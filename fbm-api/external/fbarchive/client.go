package fbarchive

import (
	"bytes"
	"context"
	"fmt"
	"mime/multipart"
	"net/http"

	"github.com/spf13/viper"
)

// Client keeps basic data to make a successful request to FBArchive service
type Client struct {
	httpClient *http.Client
	endpoint   string
	token      string
}

// Error represents errors from FB Archive service
type Error struct {
	Errors interface{} `json:"errors"`
}

func (e *Error) Error() string {
	return fmt.Sprintf("%+v", e.Errors)
}

// NewClient creates new client to interact with FBArchive service
func NewClient(httpClient *http.Client) *Client {
	return &Client{
		httpClient: httpClient,
		endpoint:   viper.GetString("fbarchive.endpoint"),
		token:      viper.GetString("fbarchive.client_token"),
	}
}

func (c *Client) createRequest(ctx context.Context, method, path string, body map[string]string) (*http.Request, error) {
	buf := &bytes.Buffer{}
	writer := multipart.NewWriter(buf)

	for k, v := range body {
		if err := writer.WriteField(k, v); err != nil {
			return nil, err
		}
	}
	if err := writer.Close(); err != nil {
		return nil, err
	}

	fullurl := c.endpoint + path

	req, err := http.NewRequestWithContext(ctx, method, fullurl, buf)
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", "Token "+c.token)

	return req, nil
}
