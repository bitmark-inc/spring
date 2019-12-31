package main

import (
	"context"
	"errors"
	"time"

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

	ctx := context.Background()
	saver := newStatSaver(b.fbDataStore)
	counter := newSentimentStatCounter(ctx, logEntry, saver)
	firstPost, err := b.bitSocialClient.GetFirstPost(ctx, accountNumber)
	logEntry.Debug(firstPost)

	if err != nil {
		logEntry.Error(err)
		sentry.CaptureException(errors.New("Request reactions failed for onwer " + accountNumber))
		return err
	}

	if firstPost == nil {
		return nil
	}

	// This user has no post at all, no sentiment to calculate
	if firstPost == nil {
		return nil
	}

	timestampOffset := absWeek(firstPost.Timestamp)
	nextWeek := absWeek(time.Now().Unix())
	toEndOfWeek := int64(7*24*60*60 - 1)

	for {
		data, err := b.bitSocialClient.GetLast7DaysOfSentiment(ctx, accountNumber, timestampOffset+toEndOfWeek)
		if err != nil {
			return err
		}
		logEntry.Debug(data)

		if err := counter.count(accountNumber, timestampOffset, data.Score); err != nil {
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
	logEntry.Info("Finish parsing sentiments")

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
	AccountNumber    string    `json:"-"`
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
}

func newSentimentStatCounter(ctx context.Context, log *log.Entry, saver *statSaver) *sentimentStatCounter {
	return &sentimentStatCounter{
		ctx:   ctx,
		saver: saver,
		log:   log,
	}
}

func (s *sentimentStatCounter) count(accountNumber string, timestamp int64, sentimentValue float64) error {
	if err := s.countWeek(accountNumber, timestamp, sentimentValue); err != nil {
		return err
	}
	if err := s.countYear(accountNumber, timestamp, sentimentValue); err != nil {
		return err
	}
	if err := s.countDecade(accountNumber, timestamp, sentimentValue); err != nil {
		return err
	}
	return nil
}

func (s *sentimentStatCounter) flush() error {
	if err := s.flushStat("week", s.currentWeekStat); err != nil {
		return err
	}
	if err := s.flushStat("year", s.currentYearStat); err != nil {
		return err
	}
	if err := s.flushStat("decade", s.currentDecadeStat); err != nil {
		return err
	}
	return nil
}

func (s *sentimentStatCounter) flushStat(period string, stat *sentimentStat) error {
	if stat != nil && !stat.IsSaved {
		if err := s.saver.save(stat.AccountNumber+"/sentiment-"+period+"-stat", stat.PeriodStartedAt, stat); err != nil {
			return err
		}
		stat.IsSaved = true
	}
	return nil
}

func (s *sentimentStatCounter) countWeek(accountNumber string, timestamp int64, sentimentValue float64) error {
	s.lastWeekStat = s.currentWeekStat

	lastSentiment := 0.0
	if s.lastWeekStat != nil {
		lastSentiment = s.lastWeekStat.Value
	}

	s.currentWeekStat = &sentimentStat{
		SectionName:      "sentiment",
		Period:           "week",
		Value:            sentimentValue,
		PeriodStartedAt:  absWeek(timestamp),
		DiffFromPrevious: getDiff(sentimentValue, lastSentiment),
		IsSaved:          false,
		AccountNumber:    accountNumber,
	}
	if err := s.flushStat("week", s.currentWeekStat); err != nil {
		return err
	}
	return nil
}

func (s *sentimentStatCounter) createEmptyYearStat(accountNumer string, timestamp int64) *sentimentStat {
	return &sentimentStat{
		SectionName:     "sentiment",
		Period:          "year",
		PeriodStartedAt: absYear(timestamp),
		IsSaved:         false,
		AccountNumber:   accountNumer,
		SubPeriodValues: make([]float64, 0),
	}
}

func (s *sentimentStatCounter) countYear(accountNumber string, timestamp int64, sentimentValue float64) error {
	yearTimestamp := absYear(timestamp)

	// New year, let's save current year before continuing to aggregate
	if s.currentYearStat != nil && s.currentYearStat.PeriodStartedAt != yearTimestamp {
		totalSentiment := 0.0
		for _, v := range s.currentYearStat.SubPeriodValues {
			totalSentiment += v
		}
		s.currentYearStat.Value = totalSentiment / float64(len(s.currentYearStat.SubPeriodValues))

		lastYearSentiment := 0.0
		if s.lastYearStat != nil {
			lastYearSentiment = s.lastYearStat.Value
		}
		s.currentYearStat.DiffFromPrevious = getDiff(s.currentYearStat.Value, lastYearSentiment)

		if err := s.flushStat("year", s.currentYearStat); err != nil {
			return err
		}
		s.lastYearStat = s.currentYearStat
		s.currentYearStat = s.createEmptyYearStat(accountNumber, timestamp)
	}

	// The first time this function is call
	if s.currentYearStat == nil {
		s.currentYearStat = s.createEmptyYearStat(accountNumber, timestamp)
	}

	s.currentYearStat.SubPeriodValues = append(s.currentYearStat.SubPeriodValues, sentimentValue)
	return nil
}

func (s *sentimentStatCounter) createEmptyDecadeStat(accountNumer string, timestamp int64) *sentimentStat {
	return &sentimentStat{
		SectionName:     "sentiment",
		Period:          "decade",
		PeriodStartedAt: absDecade(timestamp),
		IsSaved:         false,
		AccountNumber:   accountNumer,
		SubPeriodValues: make([]float64, 0),
	}
}

func (s *sentimentStatCounter) countDecade(accountNumber string, timestamp int64, sentimentValue float64) error {
	decadeTimestamp := absDecade(timestamp)

	// New decade, let's save current decade before continuing to aggregate
	if s.currentDecadeStat != nil && s.currentDecadeStat.PeriodStartedAt != decadeTimestamp {
		totalSentiment := 0.0
		for _, v := range s.currentDecadeStat.SubPeriodValues {
			totalSentiment += v
		}
		s.currentDecadeStat.Value = totalSentiment / float64(len(s.currentDecadeStat.SubPeriodValues))

		lastDecadeSentiment := 0.0
		if s.lastDecadeStat != nil {
			lastDecadeSentiment = s.lastDecadeStat.Value
		}
		s.currentDecadeStat.DiffFromPrevious = getDiff(s.currentDecadeStat.Value, lastDecadeSentiment)

		if err := s.flushStat("year", s.currentDecadeStat); err != nil {
			return err
		}
		s.lastDecadeStat = s.currentDecadeStat
		s.currentDecadeStat = s.createEmptyDecadeStat(accountNumber, timestamp)
	}

	// The first time this function is call
	if s.currentDecadeStat == nil {
		s.currentDecadeStat = s.createEmptyDecadeStat(accountNumber, timestamp)
	}

	s.currentDecadeStat.SubPeriodValues = append(s.currentDecadeStat.SubPeriodValues, sentimentValue)
	return nil
}
