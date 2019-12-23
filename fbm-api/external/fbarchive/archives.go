package fbarchive

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	log "github.com/sirupsen/logrus"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httputil"
)

func (c *Client) Login(ctx context.Context, username, password string) error {
	body := &bytes.Buffer{}
	encoder := json.NewEncoder(body)
	if err := encoder.Encode(map[string]interface{}{
		"username": username,
		"password": password,
	}); err != nil {
		return err
	}

	r, _ := http.NewRequestWithContext(ctx, "POST", c.endpoint+"/auth/token/login", body)
	r.Header.Add("Content-Type", "application/json")
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return err
	}

	var respBody struct {
		AuthToken string `json:"auth_token"`
	}
	decoder := json.NewDecoder(resp.Body)
	if err := decoder.Decode(&respBody); err != nil {
		return err
	}

	c.token = respBody.AuthToken

	return nil
}

func (c *Client) NewDataOwner(ctx context.Context, publicKey string) error {
	r, _ := c.createRequest(ctx, "POST", "/data_owners", map[string]string{
		"public_key": publicKey,
	})
	r.Header.Add("Content-Type", "application/json")
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return err
	}

	if resp.StatusCode < 300 {
		return nil
	}

	return errors.New("error when creating data owner")
}

func (c *Client) UploadArchives(ctx context.Context, data io.ReadCloser, dataOwner string) (string, error) {
	defer data.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.WriteField("data_owner", dataOwner)
	part, err := writer.CreateFormFile("file", "data.zip")
	if err != nil {
		return "", err
	}

	io.Copy(part, data)

	r, _ := http.NewRequestWithContext(ctx, "POST", c.endpoint+"/archives/", body)
	r.Header.Add("Content-Type", "multipart/form-data")
	r.Header.Add("Authorization", "Token "+c.token)
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return "", err
	}

	go func(resp *http.Response) {
		// Print out the response in console log
		dumpBytes, err := httputil.DumpResponse(resp, true)
		if err != nil {
			log.Error(err)
		}

		log.WithContext(ctx).WithField("prefix", "fbarchive").WithField("resp", string(dumpBytes)).Debug("response from data analysis server")
	}(resp)

	decoder := json.NewDecoder(resp.Body)
	var respBody struct {
		TaskID string `json:"task_id"`
		ID     int    `json:"id"`
		Status string `json:"status"`
	}

	if err := decoder.Decode(&respBody); err != nil {
		return "", err
	}

	return respBody.TaskID, nil
}

func (c *Client) GetArchiveTaskStatus(ctx context.Context, taskID string) (string, error) {
	r, _ := c.createRequest(ctx, "GET", "/tasks/"+taskID, nil)
	resp, err := c.httpClient.Do(r)
	if err != nil {
		return "", err
	}

	decoder := json.NewDecoder(resp.Body)
	var respBody struct {
		TaskID string `json:"task_id"`
		ID     int    `json:"id"`
		Status string `json:"status"`
	}

	if err := decoder.Decode(&respBody); err != nil {
		return "", err
	}

	return respBody.Status, nil
}

func (c *Client) IsReady() bool {
	return c.token != ""
}
