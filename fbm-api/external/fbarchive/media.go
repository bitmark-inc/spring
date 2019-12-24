package fbarchive

import (
	"context"
	"encoding/json"
)

func (c *Client) GetMediaPresignedURI(ctx context.Context, key string) (string, error) {
	r, _ := c.createRequest(ctx, "POST", "/media_uri/", map[string]string{
		"uri": key,
	})

	resp, err := c.httpClient.Do(r)
	if err != nil {
		return "", err
	}

	decoder := json.NewDecoder(resp.Body)
	var respBody struct {
		URI string `json:"uri"`
	}

	if err := decoder.Decode(&respBody); err != nil {
		return "", err
	}
	defer resp.Body.Close()

	return respBody.URI, nil
}
