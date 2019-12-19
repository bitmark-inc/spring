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

type postResponseData struct {
	Response struct {
		Count     int `json:"count"`
		Cursor    int `json:"cursor"`
		Remaining int `json:"remaining"`
		Results   []struct {
			AddressText     string   `json:"address_text,omitempty"`
			LatitudeNumber  float64  `json:"latitude_number,omitempty"`
			LocationText    string   `json:"location_text,omitempty"`
			LongitudeNumber float64  `json:"longitude_number,omitempty"`
			TagsListText    []string `json:"tags_list_text"`
			TimestampNumber int64    `json:"timestamp_number"`
			TypeText        string   `json:"type_text"`
			URLPlaceText    string   `json:"url_place_text"`
			PhotoText       string   `json:"photo_text"`
			VideoText       string   `json:"video_text"`
			ThumbnailText   string   `json:"thumbnail_text"`
			URLText         string   `json:"url_text"`
			TitleText       string   `json:"title_text"`
			PostText        string   `json:"post_text"`
			IDNumber        uint64   `json:"id_number"`
		} `json:"results"`
	} `json:"response"`
}

type mediaData struct {
	Type      string `json:"type"`
	Source    string `json:"source"`
	Thumbnail string `json:"thumbnail,omitempty"`
}

type postData struct {
	Timestamp int64       `json:"timestamp"`
	Type      string      `json:"type"`
	Post      string      `json:"post,omitempty"`
	ID        uint64      `json:"id"`
	Media     []mediaData `json:"mediaData,omitempty"`
	Location  string      `json:"location,omitempty"`
	URL       string      `json:"url,omitempty"`
	Title     string      `json:"title"`
	Tags      []string    `json:"tags,omitempty"`
}

func (b *BackgroundContext) extractPost(job *work.Job) error {
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
		job.Checkin(fmt.Sprintf("Fetching batch: %d", currentCursor))

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

		job.Checkin("Parse data")
		decoder := json.NewDecoder(resp.Body)
		var respData postResponseData
		if err := decoder.Decode(&respData); err != nil {
			logEntity.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
		}

		// Save to db
		for _, r := range respData.Response.Results {
			postType := ""
			var media []mediaData
			switch r.TypeText {
			case "photo":
				postType = "media"
				media = []mediaData{
					mediaData{
						Type:      "photo",
						Source:    r.PhotoText,
						Thumbnail: r.PhotoText,
					},
				}
			case "video":
				postType = "media"
				media = []mediaData{
					mediaData{
						Type:      "video",
						Source:    r.VideoText,
						Thumbnail: r.ThumbnailText,
					},
				}
			case "text":
				postType = "update"
			case "link":
				postType = "link"
			default:
				continue
			}

			// Add post
			post := postData{
				Timestamp: r.TimestampNumber,
				Type:      postType,
				Post:      r.PostText,
				ID:        r.IDNumber,
				Media:     media,
				Location:  r.LocationText,
				URL:       r.URLText,
				Title:     r.TitleText,
				Tags:      r.TagsListText,
			}
			if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post", r.TimestampNumber, post); err != nil {
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
