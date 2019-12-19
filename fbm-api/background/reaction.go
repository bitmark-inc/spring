package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httputil"

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
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	url := job.ArgString("url")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	currentCursor := 0

	for {
		// Checking job
		job.Checkin(fmt.Sprintf("Fetching reaction batch: %d", currentCursor))

		// Build url
		pagingURL := fmt.Sprintf("%s?cursor=%d", url, currentCursor)
		req, err := http.NewRequestWithContext(ctx, "GET", pagingURL, nil)
		if err != nil {
			logEntity.Error(err)
			return err
		}

		reqDump, err := httputil.DumpRequest(req, true)
		if err != nil {
			logEntity.Error(err)
		}
		logEntity.WithField("dump", string(reqDump)).Info("Request dump")

		resp, err := b.httpClient.Do(req)
		if err != nil {
			logEntity.Error(err)
			return err
		}

		// Print out the response in console log
		dumpBytes, err := httputil.DumpResponse(resp, false)
		if err != nil {
			logEntity.Error(err)
		}
		dump := string(dumpBytes)
		logEntity.Info("response: ", dump)

		if resp.StatusCode > 300 {
			logEntity.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
			return nil
		}

		job.Checkin("Parse reaction")
		decoder := json.NewDecoder(resp.Body)
		var respData reactionResponseData
		if err := decoder.Decode(&respData); err != nil {
			logEntity.Error("Request failed")
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
				logEntity.Error(err)
				sentry.CaptureException(err)
				continue
			}
		}

		// Should continue?
		if respData.Response.Remaining == 0 {
			break
		} else {
			currentCursor += respData.Response.Count
		}
	}

	logEntity.Info("Finish...")

	return nil
}

type reactionStatData struct {
	Like  int `json:"like"`
	Love  int `json:"love"`
	Haha  int `json:"haha"`
	Wow   int `json:"wow"`
	Sad   int `json:"sad"`
	Angry int `json:"angry"`
}

type reactionSubPeriodCountStat struct {
	Name string           `json:"name"`
	Data reactionStatData `json:"data"`
}

type reactionStat struct {
	SectionName      string `json:"section_name"`
	DiffFromPrevious int64  `json:"diff_from_previous"`
	Period           string `json:"period"`
	PeriodStartedAt  int64  `json:"period_started_at"`
	Quantity         uint64 `json:"quantity"`
	Groups           struct {
		Type struct {
			Data reactionStatData `json:"data"`
		} `json:"type"`
		SubPeriod []reactionSubPeriodCountStat `json:"sub_period"`
	} `json:"groups"`
}
