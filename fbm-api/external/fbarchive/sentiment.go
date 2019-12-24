package fbarchive

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
)

// SentimentData represents the data response for GET /sentiment API
type SentimentData struct {
	Timestamp int64 `json:"timestamp"`
	Score     uint8 `json:"score"`
}

// GetSentiment calls the data source to get sentiment data for an owner at a timestamp
func (c *Client) GetSentiment(ctx context.Context, dataOwner string, timestamp int64) (*SentimentData, error) {
	queryPath := fmt.Sprintf("/analysis?type=sentiment&data_owner=%s&timestamp=%d", dataOwner, timestamp)
	req, err := c.createRequest(ctx, "GET", queryPath, make(map[string]string))

	req.Header.Add("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 300 {
		return nil, errors.New("error when querying the sentiment")
	}

	decoder := json.NewDecoder(resp.Body)
	var data SentimentData

	err = decoder.Decode(&data)
	if err != nil {
		return nil, err
	}
	return &data, nil
}
