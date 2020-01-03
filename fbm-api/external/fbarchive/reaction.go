package fbarchive

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
)

// ReactionData represents the data response for GET /sentiment API
type ReactionData struct {
	ID        int64  `json:"reaction_id"`
	Timestamp int64  `json:"timestamp"`
	Title     string `json:"title"`
	Actor     string `json:"actor"`
	Reaction  string `json:"reaction"`
}

// ReactionResponse represents the full response from the archive service
type ReactionResponse struct {
	Count   int64          `json:"count"`
	Results []ReactionData `json:"results"`
}

// GetReactions calls the data source to get reaction data for an owner, returned reaction data and count
func (c *Client) GetReactions(ctx context.Context, dataOwner, orderBy string, offset int64) ([]ReactionData, int64, error) {
	queryPath := fmt.Sprintf("/reactions?data_owner=%s&order_by=%s&offset=%d&limit=10000", dataOwner, orderBy, offset)
	req, err := c.createRequest(ctx, "GET", queryPath, make(map[string]string))

	req.Header.Add("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, 0, err
	}

	if resp.StatusCode >= 300 {
		return nil, 0, errors.New("error when querying the reaction")
	}

	var data ReactionResponse
	decoder := json.NewDecoder(resp.Body)
	err = decoder.Decode(&data)
	if err != nil {
		return nil, 0, err
	}

	return data.Results, data.Count, err
}
