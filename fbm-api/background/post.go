package main

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httputil"
	"os"

	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"

	bolt "go.etcd.io/bbolt"
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
			TimestampNumber uint64   `json:"timestamp_number"`
			TypeText        string   `json:"type_text"`
			URLPlaceText    string   `json:"url_place_text"`
			TitleText       string   `json:"title_text"`
		} `json:"results"`
	} `json:"response"`
}

type postData struct {
	Timestamp int      `json:"timestamp"`
	Type      string   `json:"type"`
	Post      string   `json:"post,omitempty"`
	ID        string   `json:"id"`
	Thumbnail string   `json:"thumbnail"`
	Location  string   `json:"location"`
	URL       string   `json:"url"`
	Title     string   `json:"title"`
	Photo     []string `json:"photo"`
	Tags      []string `json:"tags"`
}

func (b *BackgroundContext) extractPost(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	url := job.ArgString("url")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	// Open a temp db for caching
	db, err := bolt.Open(os.TempDir()+"/"+accountNumber+".bolt", 0666, nil)
	if err != nil {
		return err
	}
	defer db.Close()

	logEntity.Info("Writing data to: ", db.Path())

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

		if err := extractDataAndSaveDB(respData, db); err != nil {
			return err
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

func extractDataAndSaveDB(data postResponseData, db *bolt.DB) error {
	// save to bolt db
	for _, r := range data.Response.Results {
		if err := db.Update(func(tx *bolt.Tx) error {
			postBucket, err := tx.CreateBucketIfNotExists([]byte("Post"))
			if err != nil {
				return err
			}

			postKey := make([]byte, 8)
			binary.LittleEndian.PutUint64(postKey, r.TimestampNumber)
			postValue, _ := json.Marshal(r) // Always true, ignore error here
			postBucket.Put(postKey, postValue)

			for _, tag := range r.TagsListText {
				tagBucket, err := tx.CreateBucketIfNotExists([]byte("Tag_" + tag))
				if err != nil {
					return err
				}

				// Clone exactly post value and put to tag bucket
				tagBucket.Put(postKey, postValue)
			}

			if r.LocationText != "" {
				locationBucket, err := tx.CreateBucketIfNotExists([]byte("Location_" + r.LocationText))
				if err != nil {
					return err
				}

				// Clone exactly post value and put to tag bucket
				locationBucket.Put(postKey, postValue)
			}

			return nil
		}); err != nil {
			return err
		}
	}

	return nil
}
