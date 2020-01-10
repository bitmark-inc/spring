package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/bitmark-inc/fbm-apps/fbm-api/external/fbarchive"
	"github.com/bitmark-inc/fbm-apps/fbm-api/protomodel"
	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	"github.com/golang/protobuf/proto"
	log "github.com/sirupsen/logrus"
)

func (b *BackgroundContext) extractReaction(job *work.Job) (err error) {
	defer jobEndCollectiveMetric(err, job)
	logEntry := log.WithField("prefix", job.Name+"/"+job.ID)
	accountNumber := job.ArgString("account_number")
	archiveid := job.ArgInt64("archive_id")
	if err := job.ArgError(); err != nil {
		return err
	}

	var currentOffset int64
	var total int64

	ctx := context.Background()
	saver := newStatSaver(b.fbDataStore)
	counter := newReactionStatCounter(ctx, logEntry, saver, accountNumber)

	var lastTimestamp int64
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
		for _, reaction := range reactions {
			if lastTimestamp == reaction.Timestamp {
				continue
			}
			lastTimestamp = reaction.Timestamp

			reactionData, _ := proto.Marshal(&protomodel.Reaction{
				ReactionId: reaction.ID,
				Timestamp:  reaction.Timestamp,
				Title:      reaction.Title,
				Actor:      reaction.Actor,
				Reaction:   reaction.Reaction,
			})
			if err := saver.save(accountNumber+"/reaction", reaction.Timestamp, reactionData); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}

			if err := counter.count(reaction); err != nil {
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
		"archive_id":     archiveid,
	}); err != nil {
		return err
	}

	// Mark the archive is processed
	if _, err := b.store.UpdateFBArchiveStatus(ctx, &store.FBArchiveQueryParam{
		ID: &archiveid,
	}, &store.FBArchiveQueryParam{
		Status: &store.FBArchiveStatusProcessed,
	}); err != nil {
		logEntry.Error(err)
		return err
	}

	logEntry.Info("Finish parsing reactions")

	return nil
}

type reactionStat struct {
	Reaction *protomodel.Usage
	IsSaved  bool
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

func (r *reactionStatCounter) createEmptyStat(period string, timestamp int64) *reactionStat {
	return &reactionStat{
		Reaction: &protomodel.Usage{
			SectionName:     "reaction",
			Period:          period,
			PeriodStartedAt: absPeriod(period, timestamp),
			Groups: &protomodel.Group{
				Type: &protomodel.PeriodData{
					Data: make(map[string]int64),
				},
				SubPeriod: make([]*protomodel.PeriodData, 0),
			},
		},
		IsSaved: false,
	}
}

func (r *reactionStatCounter) flushStat(period string, currentStat *reactionStat, lastStat *reactionStat) error {
	if currentStat != nil && !currentStat.IsSaved {
		// Calculate the difference
		var lastQuantity int64
		if lastStat != nil {
			lastQuantity = lastStat.Reaction.Quantity
		}
		currentStat.Reaction.DiffFromPrevious = getDiff(float64(currentStat.Reaction.Quantity), float64(lastQuantity))

		statData, _ := proto.Marshal(currentStat.Reaction)

		// Save data
		if err := r.saver.save(r.accountNumber+"/reaction-"+period+"-stat", currentStat.Reaction.PeriodStartedAt, statData); err != nil {
			return err
		}
		currentStat.IsSaved = true
	}
	return nil
}

func (r *reactionStatCounter) flush() error {
	if err := r.flushStat("week", r.currentWeekStat, r.lastWeekStat); err != nil {
		return err
	}
	if err := r.flushStat("year", r.currentYearStat, r.lastYearStat); err != nil {
		return err
	}
	if err := r.flushStat("decade", r.currentDecadeStat, r.lastDecadeStat); err != nil {
		return err
	}
	return nil
}

func (r *reactionStatCounter) count(reaction fbarchive.ReactionData) error {
	if err := r.countWeek(reaction); err != nil {
		return err
	}
	if err := r.countYear(reaction); err != nil {
		return err
	}
	if err := r.countDecade(reaction); err != nil {
		return err
	}
	return nil
}

func (r *reactionStatCounter) countWeek(reaction fbarchive.ReactionData) error {
	periodTimestamp := absWeek(reaction.Timestamp)

	// Release the current period if next period has come
	if r.currentWeekStat != nil && r.currentWeekStat.Reaction.PeriodStartedAt != periodTimestamp {
		if err := r.flushStat("week", r.currentWeekStat, r.lastWeekStat); err != nil {
			return err
		}
		r.lastWeekStat = r.currentWeekStat
		r.currentWeekStat = nil
	}

	// no data for current period yet, let's create one
	if r.currentWeekStat == nil {
		r.currentWeekStat = r.createEmptyStat("week", periodTimestamp)
	}

	r.currentWeekStat.Reaction.Quantity++
	plusOneValue(&r.currentWeekStat.Reaction.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentWeekStat.Reaction.Groups.SubPeriod
	subPeriodTimestamp := absDay(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, &protomodel.PeriodData{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int64),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentWeekStat.Reaction.Groups.SubPeriod = subPeriod

	return nil
}

func (r *reactionStatCounter) countYear(reaction fbarchive.ReactionData) error {
	periodTimestamp := absYear(reaction.Timestamp)

	// Release the current period if next period has come
	if r.currentYearStat != nil && r.currentYearStat.Reaction.PeriodStartedAt != periodTimestamp {
		if err := r.flushStat("year", r.currentYearStat, r.lastYearStat); err != nil {
			return err
		}
		r.lastYearStat = r.currentYearStat
		r.currentYearStat = nil
	}

	// no data for current period yet, let's create one
	if r.currentYearStat == nil {
		r.currentYearStat = r.createEmptyStat("year", periodTimestamp)
	}

	r.currentYearStat.Reaction.Quantity++
	plusOneValue(&r.currentYearStat.Reaction.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentYearStat.Reaction.Groups.SubPeriod
	subPeriodTimestamp := absMonth(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, &protomodel.PeriodData{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int64),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentYearStat.Reaction.Groups.SubPeriod = subPeriod

	return nil
}

func (r *reactionStatCounter) countDecade(reaction fbarchive.ReactionData) error {
	periodTimestamp := absDecade(reaction.Timestamp)

	// Release the current period if next period has come
	if r.currentDecadeStat != nil && r.currentDecadeStat.Reaction.PeriodStartedAt != periodTimestamp {
		log.Debug("Current period started at: ", periodTimestamp)
		if err := r.flushStat("decade", r.currentDecadeStat, r.lastDecadeStat); err != nil {
			return err
		}
		r.lastDecadeStat = r.currentDecadeStat
		r.currentDecadeStat = nil
	}

	// no data for current period yet, let's create one
	if r.currentDecadeStat == nil {
		r.currentDecadeStat = r.createEmptyStat("decade", periodTimestamp)
	}

	r.currentDecadeStat.Reaction.Quantity++
	plusOneValue(&r.currentDecadeStat.Reaction.Groups.Type.Data, reaction.Reaction)

	subPeriod := r.currentDecadeStat.Reaction.Groups.SubPeriod
	subPeriodTimestamp := absYear(reaction.Timestamp)
	needNewSubPeriod := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(subPeriodTimestamp, 10)

	if needNewSubPeriod {
		subPeriod = append(subPeriod, &protomodel.PeriodData{
			Name: strconv.FormatInt(subPeriodTimestamp, 10),
			Data: make(map[string]int64),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	r.currentDecadeStat.Reaction.Groups.SubPeriod = subPeriod

	return nil
}
