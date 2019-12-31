package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/bitmark-inc/fbm-apps/fbm-api/external/fbarchive"
	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

func (b *BackgroundContext) extractReaction(job *work.Job) (err error) {
	defer jobEndCollectiveMetric(err, job)
	logEntry := log.WithField("prefix", job.Name+"/"+job.ID)
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	var currentOffset int64
	var total int64

	ctx := context.Background()
	saver := newStatSaver(b.fbDataStore)
	counter := newReactionStatCounter(ctx, logEntry, saver, accountNumber)

	for {
		// Check-in job
		job.Checkin(fmt.Sprintf("Fetching reaction batch at offset: %d", currentOffset))
		reactions, t, err := b.bitSocialClient.GetReactions(ctx, accountNumber, "asc", currentOffset)
		if err != nil {
			logEntry.Error(err)
			sentry.CaptureException(errors.New("Request reactions failed for onwer " + accountNumber))
			return err
		}
		currentOffset += int64(len(reactions))
		total = t

		logEntry.WithField("Total", total).WithField("Offset: ", currentOffset).Info("Querying reactions at ", time.Now().Format("15:04:05"))

		// Save to db & count
		var lastTimestamp int64
		for _, reaction := range reactions {
			if lastTimestamp == reaction.Timestamp {
				continue
			}
			lastTimestamp = reaction.Timestamp

			if err := saver.save(accountNumber+"/reaction", reaction.Timestamp, reaction); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}

			if err := counter.count(accountNumber, reaction); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}
		}

		if currentOffset >= total {
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

	logEntry.Info("Enqueue push notification")
	if _, err := enqueuer.EnqueueUnique(jobNotificationFinish, work.Q{
		"account_number": accountNumber,
	}); err != nil {
		return err
	}

	logEntry.Info("Finish parsing reactions")

	return nil
}

type reactionSubPeriodStat struct {
	Name string         `json:"name"`
	Data map[string]int `json:"data"`
}

type reactionGroupStat struct {
	Type struct {
		Data map[string]int `json:"data"`
	} `json:"type"`
	SubPeriod []reactionSubPeriodStat `json:"sub_period"`
}

type reactionStat struct {
	SectionName      string            `json:"section_name"`
	DiffFromPrevious float64           `json:"diff_from_previous"`
	Period           string            `json:"period"`
	PeriodStartedAt  int64             `json:"period_started_at"`
	Quantity         uint64            `json:"quantity"`
	Groups           reactionGroupStat `json:"groups"`
	IsSaved          bool              `json:"-"`
}

type reactionStatCounter struct {
	lastWeekStat      *reactionStat
	currentWeekStat   *reactionStat
	lastYearStat      *reactionStat
	currentYearStat   *reactionStat
	lastDecadeStat    *reactionStat
	currentDecadeStat *reactionStat
	accountNumber     string
	ctx               context.Context
	saver             *statSaver
	log               *log.Entry
}

func newReactionStatCounter(ctx context.Context, log *log.Entry, saver *statSaver, accountNumber string) *reactionStatCounter {
	return &reactionStatCounter{
		ctx:           ctx,
		saver:         saver,
		log:           log,
		accountNumber: accountNumber,
	}
}

func (r *reactionStatCounter) createEmptyStat(period string, accountNumber string, timestamp int64) *reactionStat {
	return &reactionStat{
		SectionName:     "reaction",
		Period:          period,
		PeriodStartedAt: absPeriod(period, timestamp),
		IsSaved:         false,
		Groups: reactionGroupStat{
			Type: struct {
				Data map[string]int `json:"data"`
			}{
				Data: make(map[string]int),
			},
			SubPeriod: make([]reactionSubPeriodStat, 0),
		},
	}
}

func (r *reactionStatCounter) flushStat(period string, stat *reactionStat) error {
	if stat != nil && !stat.IsSaved {
		if err := r.saver.save(r.accountNumber+"/reaction-"+period+"-stat", stat.PeriodStartedAt, stat); err != nil {
			return err
		}
		stat.IsSaved = true
	}
	return nil
}

func (r *reactionStatCounter) flush() error {
	if err := r.flushStat("week", r.currentWeekStat); err != nil {
		return err
	}
	if err := r.flushStat("year", r.currentYearStat); err != nil {
		return err
	}
	if err := r.flushStat("decade", r.currentDecadeStat); err != nil {
		return err
	}
	return nil
}

func (r *reactionStatCounter) count(accountNumber string, reaction fbarchive.ReactionData) error {
	if err := r.countWeek(accountNumber, reaction); err != nil {
		return err
	}
	if err := r.countYear(accountNumber, reaction); err != nil {
		return err
	}
	if err := r.countDecade(accountNumber, reaction); err != nil {
		return err
	}
	return nil
}

func (r *reactionStatCounter) countWeek(accountNumber string, reaction fbarchive.ReactionData) error {
	periodTimestamp := absWeek(reaction.Timestamp)

	if r.currentWeekStat != nil && r.currentWeekStat.PeriodStartedAt != periodTimestamp {
		var lastPeriodQuantity uint64
		if r.lastWeekStat != nil {
			lastPeriodQuantity = r.lastWeekStat.Quantity
		}

		r.currentWeekStat.DiffFromPrevious = getDiff(float64(r.currentWeekStat.Quantity), float64(lastPeriodQuantity))

		if err := r.flushStat("week", r.currentWeekStat); err != nil {
			return err
		}
		r.lastWeekStat = r.currentWeekStat
		r.currentWeekStat = r.createEmptyStat("week", accountNumber, periodTimestamp)
	}

	// The first time the function is called
	if r.currentWeekStat == nil {
		r.currentWeekStat = r.createEmptyStat("week", accountNumber, periodTimestamp)
	}

	r.currentWeekStat.Quantity++
	plusOneValue(&r.currentWeekStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentWeekStat.Groups.SubPeriod
	subPeriodTimestamp := absDay(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentWeekStat.Groups.SubPeriod = subPeriod

	return nil
}

func (r *reactionStatCounter) countYear(accountNumber string, reaction fbarchive.ReactionData) error {
	periodTimestamp := absYear(reaction.Timestamp)

	if r.currentYearStat != nil && r.currentYearStat.PeriodStartedAt != periodTimestamp {
		var lastPeriodQuantity uint64
		if r.lastYearStat != nil {
			lastPeriodQuantity = r.lastYearStat.Quantity
		}

		r.currentYearStat.DiffFromPrevious = getDiff(float64(r.currentYearStat.Quantity), float64(lastPeriodQuantity))

		if err := r.flushStat("year", r.currentYearStat); err != nil {
			return err
		}
		r.lastYearStat = r.currentYearStat
		r.currentYearStat = r.createEmptyStat("year", accountNumber, periodTimestamp)
	}

	// The first time the function is called
	if r.currentYearStat == nil {
		r.currentYearStat = r.createEmptyStat("year", accountNumber, periodTimestamp)
	}

	r.currentYearStat.Quantity++
	plusOneValue(&r.currentYearStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentYearStat.Groups.SubPeriod
	subPeriodTimestamp := absMonth(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentYearStat.Groups.SubPeriod = subPeriod

	return nil
}

func (r *reactionStatCounter) countDecade(accountNumber string, reaction fbarchive.ReactionData) error {
	periodTimestamp := absDecade(reaction.Timestamp)

	if r.currentDecadeStat != nil && r.currentDecadeStat.PeriodStartedAt != periodTimestamp {
		var lastPeriodQuantity uint64
		if r.lastDecadeStat != nil {
			lastPeriodQuantity = r.lastDecadeStat.Quantity
		}

		r.currentDecadeStat.DiffFromPrevious = getDiff(float64(r.currentDecadeStat.Quantity), float64(lastPeriodQuantity))

		if err := r.flushStat("decade", r.currentDecadeStat); err != nil {
			return err
		}
		r.lastDecadeStat = r.currentDecadeStat
		r.currentDecadeStat = r.createEmptyStat("decade", accountNumber, periodTimestamp)
	}

	// The first time the function is called
	if r.currentDecadeStat == nil {
		r.currentDecadeStat = r.createEmptyStat("decade", accountNumber, periodTimestamp)
	}

	r.currentDecadeStat.Quantity++
	plusOneValue(&r.currentDecadeStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentDecadeStat.Groups.SubPeriod
	subPeriodTimestamp := absYear(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentDecadeStat.Groups.SubPeriod = subPeriod

	return nil
}
