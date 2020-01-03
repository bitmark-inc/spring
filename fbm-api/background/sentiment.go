package main

import (
	"context"
	"errors"
	"math"

	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

func (b *BackgroundContext) extractSentiment(job *work.Job) (err error) {
	defer jobEndCollectiveMetric(err, job)

	logEntry := log.WithField("prefix", job.Name+"/"+job.ID)

	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	defer func() error {
		if err == nil {
			logEntry.Info("Finish parsing sentiments")

			if _, err := enqueuer.EnqueueUnique(jobAnalyzeReactions, work.Q{
				"account_number": accountNumber,
			}); err != nil {
				return err
			}
		}
		return err
	}()

	ctx := context.Background()
	saver := newStatSaver(b.fbDataStore)
	counter := newSentimentStatCounter(ctx, logEntry, saver, accountNumber)

	// Get first post to get the starting timestamp
	firstPost, err := b.bitSocialClient.GetFirstPost(ctx, accountNumber)
	if err != nil {
		logEntry.Error(err)
		sentry.CaptureException(errors.New("Request first post failed for onwer " + accountNumber))
		return err
	}

	// This user has no post at all, no sentiment to calculate
	if firstPost == nil {
		return nil
	}

	// Get last post to get the ending timestamp
	lastPost, err := b.bitSocialClient.GetLastPost(ctx, accountNumber)
	if err != nil {
		logEntry.Error(err)
		sentry.CaptureException(errors.New("Request last post failed for onwer " + accountNumber))
		return err
	}

	// last post can not be nil
	if lastPost == nil {
		err := errors.New("Last post can not be nil")
		logEntry.Error(err)
		sentry.CaptureException(err)
		return err
	}

	timestampOffset := absWeek(firstPost.Timestamp)
	nextWeek := absWeek(lastPost.Timestamp) + 7*24*60*60
	toEndOfWeek := int64(7*24*60*60 - 1)

	for {
		data, err := b.bitSocialClient.GetLast7DaysOfSentiment(ctx, accountNumber, timestampOffset+toEndOfWeek)
		if err != nil {
			return err
		}
		logEntry.Debug(data)

		if err := counter.count(timestampOffset, data.Score); err != nil {
			logEntry.Error(err)
			sentry.CaptureException(err)
			return err
		}

		timestampOffset += 7 * 24 * 60 * 60 // means next week
		if timestampOffset >= nextWeek {
			break
		}
	}

	if err := counter.flush(); err != nil {
		logEntry.Error(err)
		sentry.CaptureException(err)
		return err
	}
	if err := saver.flush(); err != nil {
		logEntry.Error(err)
		sentry.CaptureException(err)
		return err
	}

	return nil
}

type sentimentStat struct {
	SectionName      string    `json:"section_name"`
	Period           string    `json:"period"`
	Quantity         int       `json:"quantity"`
	Value            float64   `json:"value"`
	PeriodStartedAt  int64     `json:"period_started_at"`
	DiffFromPrevious float64   `json:"diff_from_previous"`
	SubPeriodValues  []float64 `json:"-"`
	IsSaved          bool      `json:"-"`
}

type sentimentStatCounter struct {
	lastWeekStat      *sentimentStat
	currentWeekStat   *sentimentStat
	lastYearStat      *sentimentStat
	currentYearStat   *sentimentStat
	lastDecadeStat    *sentimentStat
	currentDecadeStat *sentimentStat
	ctx               context.Context
	saver             *statSaver
	log               *log.Entry
	accountNumber     string
}

func newSentimentStatCounter(ctx context.Context, log *log.Entry, saver *statSaver, accountNumber string) *sentimentStatCounter {
	return &sentimentStatCounter{
		ctx:           ctx,
		saver:         saver,
		log:           log,
		accountNumber: accountNumber,
	}
}

func (s *sentimentStatCounter) count(timestamp int64, sentimentValue float64) error {
	if err := s.countWeek(timestamp, sentimentValue); err != nil {
		return err
	}
	if err := s.countYear(timestamp, sentimentValue); err != nil {
		return err
	}
	if err := s.countDecade(timestamp, sentimentValue); err != nil {
		return err
	}
	return nil
}

func (s *sentimentStatCounter) flush() error {
	if err := s.flushStat("week", s.currentWeekStat, s.lastWeekStat); err != nil {
		return err
	}
	if err := s.flushStat("year", s.currentYearStat, s.lastYearStat); err != nil {
		return err
	}
	if err := s.flushStat("decade", s.currentDecadeStat, s.lastDecadeStat); err != nil {
		return err
	}
	return nil
}

func (s *sentimentStatCounter) flushStat(period string, currentStat *sentimentStat, lastStat *sentimentStat) error {
	if currentStat != nil && !currentStat.IsSaved {
		currentStat.Value = s.averageSentiment(currentStat.SubPeriodValues)

		lastSentiment := 0.0
		if lastStat != nil {
			lastSentiment = lastStat.Value
		}
		currentStat.DiffFromPrevious = getDiff(currentStat.Value, lastSentiment)

		if err := s.saver.save(s.accountNumber+"/sentiment-"+period+"-stat", currentStat.PeriodStartedAt, currentStat); err != nil {
			return err
		}
		currentStat.IsSaved = true
	}
	return nil
}

func (s *sentimentStatCounter) averageSentiment(sentiments []float64) float64 {
	totalSentiment := 0.0
	for _, v := range sentiments {
		totalSentiment += v
	}
	averageSentiment := totalSentiment / float64(len(sentiments))
	return math.Round(averageSentiment)
}

func (s *sentimentStatCounter) createEmptyStat(period string, timestamp int64) *sentimentStat {
	return &sentimentStat{
		SectionName:     "sentiment",
		Period:          period,
		PeriodStartedAt: absPeriod(period, timestamp),
		IsSaved:         false,
		SubPeriodValues: make([]float64, 0),
	}
}

func (s *sentimentStatCounter) countWeek(timestamp int64, sentimentValue float64) error {
	periodTimestamp := absWeek(timestamp)

	// flush the current period to give space for next period
	if s.currentWeekStat != nil && s.currentWeekStat.PeriodStartedAt != periodTimestamp {
		if err := s.flushStat("week", s.currentWeekStat, s.lastWeekStat); err != nil {
			return err
		}
		s.lastWeekStat = s.currentWeekStat
		s.currentWeekStat = nil
	}

	// no current period, let's create a new one
	if s.currentWeekStat == nil {
		s.currentWeekStat = s.createEmptyStat("week", timestamp)
	}

	s.currentWeekStat.SubPeriodValues = append(s.currentWeekStat.SubPeriodValues, sentimentValue)
	return nil
}

func (s *sentimentStatCounter) countYear(timestamp int64, sentimentValue float64) error {
	periodTimestamp := absYear(timestamp)

	// flush the current period to give space for next period
	if s.currentYearStat != nil && s.currentYearStat.PeriodStartedAt != periodTimestamp {
		if err := s.flushStat("year", s.currentYearStat, s.lastYearStat); err != nil {
			return err
		}
		s.lastYearStat = s.currentYearStat
		s.currentYearStat = nil
	}

	// no current period, let's create a new one
	if s.currentYearStat == nil {
		s.currentYearStat = s.createEmptyStat("year", timestamp)
	}

	s.currentYearStat.SubPeriodValues = append(s.currentYearStat.SubPeriodValues, sentimentValue)
	return nil
}

func (s *sentimentStatCounter) countDecade(timestamp int64, sentimentValue float64) error {
	periodTimestamp := absDecade(timestamp)

	// New decade, let's save current decade before continuing to aggregate
	if s.currentDecadeStat != nil && s.currentDecadeStat.PeriodStartedAt != periodTimestamp {
		if err := s.flushStat("decade", s.currentDecadeStat, s.lastDecadeStat); err != nil {
			return err
		}
		s.lastDecadeStat = s.currentDecadeStat
		s.currentDecadeStat = nil
	}

	// The first time this function is call
	if s.currentDecadeStat == nil {
		s.currentDecadeStat = s.createEmptyStat("decade", timestamp)
	}

	s.currentDecadeStat.SubPeriodValues = append(s.currentDecadeStat.SubPeriodValues, sentimentValue)
	return nil
}
