package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httputil"
	"sort"
	"strconv"
	"strings"

	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

type reactionResponseData struct {
	Response struct {
		Count     int `json:"count"`
		Cursor    int `json:"cursor"`
		Remaining int `json:"remaining"`
		Results   []struct {
			ActorText       string `json:"actor_text"`
			IDNumber        uint64 `json:"id_number"`
			ReactionText    string `json:"reaction_text"`
			TimestampNumber int64  `json:"timestamp_number"`
			TitleText       string `json:"title_text"`
		} `json:"results"`
	} `json:"response"`
}

type reactionData struct {
	ID        uint64 `json:"id"`
	Type      string `json:"stype"`
	Timestamp int64  `json:"timestamp"`
	Title     string `json:"title"`
}

func (b *BackgroundContext) extractReaction(job *work.Job) error {
	logEntry := log.WithField("prefix", job.Name+"/"+job.ID)
	url := job.ArgString("url")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	currentCursor := 0

	reactions := make([]reactionData, 0)

	for {
		// Checking job
		job.Checkin(fmt.Sprintf("Fetching reaction batch: %d", currentCursor))

		// Build url
		pagingURL := fmt.Sprintf("%s?cursor=%d", url, currentCursor)
		req, err := http.NewRequestWithContext(ctx, "GET", pagingURL, nil)
		if err != nil {
			logEntry.Error(err)
			return err
		}

		reqDump, err := httputil.DumpRequest(req, true)
		if err != nil {
			logEntry.Error(err)
		}
		logEntry.WithField("dump", string(reqDump)).Info("Request dump")

		resp, err := b.httpClient.Do(req)
		if err != nil {
			logEntry.Error(err)
			return err
		}

		// Print out the response in console log
		dumpBytes, err := httputil.DumpResponse(resp, false)
		if err != nil {
			logEntry.Error(err)
		}
		dump := string(dumpBytes)
		logEntry.Info("response: ", dump)

		if resp.StatusCode > 300 {
			logEntry.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
			return nil
		}

		job.Checkin("Parse reaction")
		decoder := json.NewDecoder(resp.Body)
		var respData reactionResponseData
		if err := decoder.Decode(&respData); err != nil {
			logEntry.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
		}

		// Save to db
		for _, r := range respData.Response.Results {
			reaction := reactionData{
				ID:        r.IDNumber,
				Type:      r.ReactionText,
				Timestamp: r.TimestampNumber,
				Title:     r.TitleText,
			}

			if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction", r.TimestampNumber, reaction); err != nil {
				logEntry.Error(err)
				sentry.CaptureException(err)
				return err
			}
			reactions = append(reactions, reaction)
		}

		// Should continue?
		if respData.Response.Remaining == 0 {
			break
		} else {
			currentCursor += respData.Response.Count
		}
	}

	sort.Slice(reactions, func(i, j int) bool {
		return reactions[i].Timestamp < reactions[j].Timestamp
	})

	for _, reaction := range reactions {
		if err := b.countReaction(ctx, logEntry, accountNumber, &reaction); err != nil {
			logEntry.Error(err)
			sentry.CaptureException(err)
			return err
		}
	}

	if err := b.countReaction(ctx, logEntry, accountNumber, nil); err != nil {
		logEntry.Error(err)
		sentry.CaptureException(err)
		return err
	}

	logEntry.Info("Finish...")

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

func (b *BackgroundContext) countReaction(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *reactionData) error {
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

func (b *BackgroundContext) countReactionToWeek(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *reactionData) error {
	// if pushing nil to count, flush the last week
	if reaction == nil && currentWeekReactionStat != nil {
		currentWeekReactionStat.DiffFromPrevious = getDiff(currentWeekReactionStat.Quantity, lastWeekQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-week-stat", currentWeekReactionStat.PeriodStartedAt, currentWeekReactionStat)
		logEntry.WithField("week stat:", currentWeekReactionStat).Info()
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
		logEntry.WithField("week stat:", currentWeekReactionStat).Info()
		if (weekTimestamp - 7*24*60*60) == currentWeekReactionStat.PeriodStartedAt {
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
	plusOneValue(&currentWeekReactionStat.Groups.Type.Data, strings.ToLower(reaction.Type))

	subPeriod := currentWeekReactionStat.Groups.SubPeriod
	dayTimestamp := absDay(reaction.Timestamp)
	needNewDay := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(dayTimestamp, 10)

	if needNewDay {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(dayTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, strings.ToLower(reaction.Type))
	currentWeekReactionStat.Groups.SubPeriod = subPeriod

	return nil
}

func (b *BackgroundContext) countReactionToYear(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *reactionData) error {
	// if pushing nil to count, flush the last year
	if reaction == nil && currentYearReactionStat != nil {
		currentYearReactionStat.DiffFromPrevious = getDiff(currentYearReactionStat.Quantity, lastYearQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-year-stat", currentYearReactionStat.PeriodStartedAt, currentYearReactionStat)
		logEntry.WithField("year stat:", currentYearReactionStat).Info()
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
		logEntry.WithField("year stat:", currentYearReactionStat).Info()
		if (yearTimestamp - 7*24*60*60) == currentYearReactionStat.PeriodStartedAt {
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
	plusOneValue(&currentYearReactionStat.Groups.Type.Data, strings.ToLower(reaction.Type))

	subPeriod := currentYearReactionStat.Groups.SubPeriod
	monthTimestamp := absMonth(reaction.Timestamp)
	needNewMonth := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(monthTimestamp, 10)

	if needNewMonth {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(monthTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, strings.ToLower(reaction.Type))
	currentYearReactionStat.Groups.SubPeriod = subPeriod

	return nil
}

func (b *BackgroundContext) countReactionToDecade(ctx context.Context, logEntry *log.Entry, accountNumber string, reaction *reactionData) error {
	// if pushing nil to count, flush the last decade
	if reaction == nil && currentDecadeReactionStat != nil {
		currentDecadeReactionStat.DiffFromPrevious = getDiff(currentDecadeReactionStat.Quantity, lastDecadeQuantity)
		err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/reaction-decade-stat", currentDecadeReactionStat.PeriodStartedAt, currentDecadeReactionStat)
		logEntry.WithField("decade stat:", currentDecadeReactionStat).Info()
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
		logEntry.WithField("decade stat:", currentDecadeReactionStat).Info()
		if (decadeTimestamp - 7*24*60*60) == currentDecadeReactionStat.PeriodStartedAt {
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
	plusOneValue(&currentDecadeReactionStat.Groups.Type.Data, strings.ToLower(reaction.Type))

	subPeriod := currentDecadeReactionStat.Groups.SubPeriod
	yearTimestamp := absMonth(reaction.Timestamp)
	needNewMonth := len(subPeriod) == 0 || subPeriod[len(subPeriod)-1].Name != strconv.FormatInt(yearTimestamp, 10)

	if needNewMonth {
		subPeriod = append(subPeriod, reactionSubPeriodStat{
			Name: strconv.FormatInt(yearTimestamp, 10),
			Data: make(map[string]int),
		})
	}
	plusOneValue(&subPeriod[len(subPeriod)-1].Data, strings.ToLower(reaction.Type))
	currentDecadeReactionStat.Groups.SubPeriod = subPeriod

	return nil
}
