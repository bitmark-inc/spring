package fbarchive

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http/httputil"

	log "github.com/sirupsen/logrus"
)

type PostData struct {
	Count   int `json:"count"`
	Results []struct {
		PostID                uint64 `json:"post_id"`
		Timestamp             int64  `json:"timestamp"`
		UpdateTimestamp       int64  `json:"update_timestamp"`
		Date                  string `json:"date"`
		Weekday               int    `json:"weekday"`
		Title                 string `json:"title"`
		Post                  string `json:"post"`
		ExternalContextURL    string `json:"external_context_url"`
		ExternalContextSource string `json:"external_context_source"`
		ExternalContextName   string `json:"external_context_name"`
		EventName             string `json:"event_name"`
		EventStartTimestamp   int64  `json:"event_start_timestamp"`
		EventEndTimestamp     int64  `json:"event_end_timestamp"`
		MediaAttached         bool   `json:"media_attached"`
		Sentiment             string `json:"sentiment"`
		PostMedia             []struct {
			PkID              int    `json:"pk_id"`
			PostID            int    `json:"post_id"`
			PmID              int    `json:"pm_id"`
			MediaURI          string `json:"media_uri"`
			FilenameExtension string `json:"filename_extension"`
			DataOwner         string `json:"data_owner"`
		} `json:"post_media"`
		Tags []struct {
			Tfid      int    `json:"tfid"`
			Tags      string `json:"tags"`
			PostID    int    `json:"post_id"`
			FriendID  int    `json:"friend_id"`
			DataOwner string `json:"data_owner"`
		} `json:"tags"`
		Place []struct {
			PpID      int    `json:"pp_id"`
			Name      string `json:"name"`
			Address   string `json:"address"`
			Latitude  string `json:"latitude"`
			Longitude string `json:"longitude"`
		} `json:"place"`
		DataOwner string `json:"data_owner"`
	} `json:"results"`
}

func (c *Client) GetPosts(ctx context.Context, accountNumber string, offset int) (*PostData, error) {
	r, _ := c.createRequest(ctx, "GET", fmt.Sprintf("/posts?data_owner=%s&offset=%d&order_by=asc", accountNumber, offset), nil)
	reqDumpByte, err := httputil.DumpRequest(r, false)
	if err != nil {
		log.Error(err)
	}

	log.WithContext(ctx).WithField("prefix", "fbarchive").WithField("req", string(reqDumpByte)).Debug("request to data analysis server")

	resp, err := c.httpClient.Do(r)
	if err != nil {
		return nil, err
	}

	// Print out the response in console log
	dumpBytes, err := httputil.DumpResponse(resp, true)
	if err != nil {
		log.Error(err)
	}

	log.WithContext(ctx).WithField("prefix", "fbarchive").WithField("resp", string(dumpBytes)).Debug("response from data analysis server")

	decoder := json.NewDecoder(resp.Body)
	var respBody PostData
	defer resp.Body.Close()

	if err := decoder.Decode(&respBody); err != nil {
		return nil, err
	}

	return &respBody, nil
}
