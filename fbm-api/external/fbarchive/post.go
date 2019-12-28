package fbarchive

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http/httputil"

	log "github.com/sirupsen/logrus"
)

// PostData represents a single post returned by the API
type PostData struct {
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
}

// PostsResponse represents the full repsonse from the Posts API
type PostsResponse struct {
	Count   int        `json:"count"`
	Results []PostData `json:"results"`
}

// GetPosts returns the list of posts in the ascending timestamp order, limit by 1000
func (c *Client) GetPosts(ctx context.Context, accountNumber string, offset int) (*PostsResponse, error) {
	return c.getPosts(ctx, accountNumber, offset, 1000, "asc")
}

// GetFirstPost returns the very first post of this account
func (c *Client) GetFirstPost(ctx context.Context, accountNumber string) (*PostData, error) {
	postResponse, err := c.getPosts(ctx, accountNumber, 0, 1, "asc")
	if err != nil {
		return nil, err
	}

	if len(postResponse.Results) == 0 {
		return nil, nil
	}

	return &postResponse.Results[0], nil
}

func (c *Client) getPosts(ctx context.Context, accountNumber string, offset, limit int, orderBy string) (*PostsResponse, error) {
	r, _ := c.createRequest(ctx, "GET", fmt.Sprintf("/posts?data_owner=%s&order_by=%s&limit=%d&offset=%d", accountNumber, orderBy, limit, offset), nil)
	_, err := httputil.DumpRequest(r, false)
	if err != nil {
		log.Error(err)
	}

	resp, err := c.httpClient.Do(r)
	if err != nil {
		return nil, err
	}

	// Print out the response in console log
	_, err = httputil.DumpResponse(resp, true)
	if err != nil {
		log.Error(err)
	}

	decoder := json.NewDecoder(resp.Body)
	var respBody PostsResponse
	defer resp.Body.Close()

	if err := decoder.Decode(&respBody); err != nil {
		return nil, err
	}

	return &respBody, nil
}
