package fbarchive

import (
	"bytes"
	"context"
	"encoding/json"
	log "github.com/sirupsen/logrus"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httputil"
)

func (c *Client) uploadArchives(ctx context.Context, data io.ReadCloser, fbid string) error {
	defer data.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("data", "data.zip")
	if err != nil {
		return err
	}

	io.Copy(part, data)

	r, _ := http.NewRequestWithContext(ctx, "POST", c.endpoint+"/archives", body)
	r.Header.Add("Content-Type", "multipart/form-data")
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return err
	}

	go func(resp *http.Response) {
		// Print out the response in console log
		dumpBytes, err := httputil.DumpResponse(resp, true)
		if err != nil {
			log.Error(err)
		}

		log.WithContext(ctx).WithField("prefix", "fbarchive").WithField("resp", string(dumpBytes)).Debug("response from onesignal")
	}(resp)

	if resp.StatusCode < 300 {
		return nil
	}

	// Decode response body to see what actually happened
	decoder := json.NewDecoder(resp.Body)
	var errBody Error
	if err := decoder.Decode(&errBody); err != nil {
		return err
	}

	return &errBody
}
