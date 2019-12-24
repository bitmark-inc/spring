package fbarchive

import (
	"context"
	"encoding/json"
	"fmt"
)

type PostData struct {
	Count   int `json:"count"`
	Results []struct {
		PostID                uint64 `json:"post_id"`
		Timestamp             int64  `json:"timestamp"`
		UpdateTimestamp       int64  `json:"update_timestamp"`
		Date                  string `json:"date"`
		Weekday               string `json:"weekday"`
		Title                 string `json:"title"`
		Post                  string `json:"post"`
		ExternalContextURL    string `json:"external_context_url"`
		ExternalContextSource string `json:"external_context_source"`
		ExternalContextName   string `json:"external_context_name"`
		EventName             string `json:"event_name"`
		EventStartTimestamp   int64  `json:"event_start_timestamp"`
		EventEndTimestamp     int64  `json:"event_end_timestamp"`
		MediaAttached         bool   `json:"media_attached"`
		Media                 []struct {
			MediaURI          string `json:"media_uri"`
			ThumbnailURI      string `json:"thumbnail_uri"`
			FilenameExtension string `json:"filename_extension"`
		} `json:"media"`
		Tags []struct {
			FriendID   uint64 `json:"friend_id"`
			FriendName string `json:"friend_name"`
			Timestamp  int64  `json:"timestamp"`
			DataOwner  string `json:"data_owner"`
		} `json:"tags"`
		Place []struct {
			PlaceID   int    `json:"place_id"`
			Place     string `json:"place"`
			Latitude  string `json:"latitude"`
			Longitude string `json:"longitude"`
			PlaceType string `json:"place_type"`
			DataOwner string `json:"data_owner"`
		} `json:"place"`
		DataOwner string `json:"data_owner"`
	} `json:"results"`
}

func (c *Client) GetPosts(ctx context.Context, accountNumber string, offset int) (*PostData, error) {
	r, _ := c.createRequest(ctx, "GET", fmt.Sprintf("/posts?data_owner=%s&offset=%d", accountNumber, offset), nil)
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return nil, err
	}

	decoder := json.NewDecoder(resp.Body)
	var respBody PostData
	defer resp.Body.Close()

	if err := decoder.Decode(&respBody); err != nil {
		return nil, err
	}

	return &respBody, nil
}
