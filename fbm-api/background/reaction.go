package main

import (
	"context"
	"errors"
	"fmt"
	"strconv"

	"github.com/bitmark-inc/fbm-apps/fbm-api/external/fbarchive"
	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

func (b *BackgroundContext) extractReaction(job *work.Job) error {
	logEntry := log.WithField("prefix", job.Name+"/"+job.ID)
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()
	var currentOffset int64
	var total int64

	for {
		// Checking job
		job.Checkin(fmt.Sprintf("Fetching reaction batch at offset: %d", currentOffset))
		reactions, t, err := b.bitSocialClient.GetReactions(ctx, accountNumber, "asc", currentOffset)
		if err != nil {
			logEntry.Error(err)
			sentry.CaptureException(errors.New("Request reactions failed for onwer " + accountNumber))
			// return err
			continue
		}
		currentOffset += int64(len(reactions))
		total = t

		logEntry.WithField("Total", total).WithField("Offset: ", currentOffset).Info("Querying reactions")

		// Save to db & count
		for _, reaction := range reactions {
			if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction", reaction.Timestamp, reaction); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}

			if err := b.countReaction(ctx, logEntry, accountNumber, &reaction); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}
		}

		if currentOffset >= total {
			break
		}
	}

	if err := b.countReaction(ctx, logEntry, accountNumber, nil); err != nil {
		logEntry.Error(err)
		sentry.CaptureException(err)
		return err
	}

	logEntry.Info("Enqueue parsing reaction")
	if _, err := enqueuer.EnqueueUnique("analyze_reactions", work.Q{
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
}

var currentWeekReactionStat, currentYearReactionStat, currentDecadeReactionStat *reactionStat
var lastWeekQuantity, lastYearQuantity, lastDecadeQuantity uint64

func (b *BackgroundContext) countReaction(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *fbarchive.ReactionData) error {
	err := b.countReactionToWeek(ctx, logEntry, accountNumber, reaction)
	if err != nil {
		return err
	}
	err = b.countReactionToYear(ctx, logEntry, accountNumber, reaction)
	if err != nil {
		return err
	}
	err = b.countReactionToDecade(ctx, logEntry, accountNumber, reaction)
	return err
}

func (b *BackgroundContext) countReactionToWeek(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *fbarchive.ReactionData) error {
	// if pushing nil to count, flush the last week
	if reaction == nil && currentWeekReactionStat != nil {
		currentWeekReactionStat.DiffFromPrevious = getDiff(currentWeekReactionStat.Quantity, lastWeekQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-week-stat", currentWeekReactionStat.PeriodStartedAt, currentWeekReactionStat)
		return err
	}

	// if having data, let's count
	weekTimestamp := absWeek(reaction.Timestamp)
	needNewWeek := false
	if currentWeekReactionStat != nil && currentWeekReactionStat.PeriodStartedAt != weekTimestamp {
		currentWeekReactionStat.DiffFromPrevious = getDiff(currentWeekReactionStat.Quantity, lastWeekQuantity)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-week-stat", currentWeekReactionStat.PeriodStartedAt, currentWeekReactionStat); err != nil {
			return err
		}
		if absWeek(weekTimestamp-1) == currentWeekReactionStat.PeriodStartedAt {
			lastWeekQuantity = currentWeekReactionStat.Quantity
		} else {
			lastWeekQuantity = 0
		}
		needNewWeek = true
	}

	if currentWeekReactionStat == nil {
		needNewWeek = true
	}

	if needNewWeek {
		currentWeekReactionStat = &reactionStat{
			SectionName:      "reactions",
			DiffFromPrevious: 5,
			Period:           "week",
			PeriodStartedAt:  weekTimestamp,
			Quantity:         0,
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

	currentWeekReactionStat.Quantity++
	plusOneValue(&currentWeekReactionStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := currentWeekReactionStat.Groups.SubPeriod
	dayTimestamp := absDay(reaction.Timestamp)
	needNewDay := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(dayTimestamp, 10)

	if needNewDay {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(dayTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	currentWeekReactionStat.Groups.SubPeriod = subPeriod

	return nil
}

func (b *BackgroundContext) countReactionToYear(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *fbarchive.ReactionData) error {
	// if pushing nil to count, flush the last year
	if reaction == nil && currentYearReactionStat != nil {
		currentYearReactionStat.DiffFromPrevious = getDiff(currentYearReactionStat.Quantity, lastYearQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-year-stat", currentYearReactionStat.PeriodStartedAt, currentYearReactionStat)
		return err
	}

	// if having data, let's count
	yearTimestamp := absYear(reaction.Timestamp)
	needNewYear := false
	if currentYearReactionStat != nil && currentYearReactionStat.PeriodStartedAt != yearTimestamp {
		currentYearReactionStat.DiffFromPrevious = getDiff(currentYearReactionStat.Quantity, lastYearQuantity)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-year-stat", currentYearReactionStat.PeriodStartedAt, currentYearReactionStat); err != nil {
			return err
		}
		if absYear(yearTimestamp-1) == currentYearReactionStat.PeriodStartedAt {
			lastYearQuantity = currentYearReactionStat.Quantity
		} else {
			lastYearQuantity = 0
		}
		needNewYear = true
	}

	if currentYearReactionStat == nil {
		needNewYear = true
	}

	if needNewYear {
		currentYearReactionStat = &reactionStat{
			SectionName:      "reactions",
			DiffFromPrevious: 5,
			Period:           "year",
			PeriodStartedAt:  yearTimestamp,
			Quantity:         0,
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

	currentYearReactionStat.Quantity++
	plusOneValue(&currentYearReactionStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := currentYearReactionStat.Groups.SubPeriod
	monthTimestamp := absMonth(reaction.Timestamp)
	needNewMonth := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(monthTimestamp, 10)

	if needNewMonth {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(monthTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	currentYearReactionStat.Groups.SubPeriod = subPeriod

	return nil
}

func (b *BackgroundContext) countReactionToDecade(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *fbarchive.ReactionData) error {
	// if pushing nil to count, flush the last decade
	if reaction == nil && currentDecadeReactionStat != nil {
		currentDecadeReactionStat.DiffFromPrevious = getDiff(currentDecadeReactionStat.Quantity, lastDecadeQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-decade-stat", currentDecadeReactionStat.PeriodStartedAt, currentDecadeReactionStat)
		return err
	}

	// if having data, let's count
	decadeTimestamp := absDecade(reaction.Timestamp)
	needNewDecade := false
	if currentDecadeReactionStat != nil && currentDecadeReactionStat.PeriodStartedAt != decadeTimestamp {
		currentDecadeReactionStat.DiffFromPrevious = getDiff(currentDecadeReactionStat.Quantity, lastDecadeQuantity)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-decade-stat", currentDecadeReactionStat.PeriodStartedAt, currentDecadeReactionStat); err != nil {
			return err
		}
		if absDecade(decadeTimestamp-1) == currentDecadeReactionStat.PeriodStartedAt {
			lastDecadeQuantity = currentDecadeReactionStat.Quantity
		} else {
			lastDecadeQuantity = 0
		}
		needNewDecade = true
	}

	if currentDecadeReactionStat == nil {
		needNewDecade = true
	}

	if needNewDecade {
		currentDecadeReactionStat = &reactionStat{
			SectionName:      "reactions",
			DiffFromPrevious: 5,
			Period:           "decade",
			PeriodStartedAt:  decadeTimestamp,
			Quantity:         0,
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

	currentDecadeReactionStat.Quantity++
	plusOneValue(&currentDecadeReactionStat.Groups.Type.Data, reaction.Reaction)

	subPeriod := currentDecadeReactionStat.Groups.SubPeriod
	yearTimestamp := absYear(reaction.Timestamp)
	needNewYear := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(yearTimestamp, 10)

	if needNewYear {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(yearTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, reaction.Reaction)
	currentDecadeReactionStat.Groups.SubPeriod = subPeriod

	return nil
}
