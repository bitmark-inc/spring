package geoservice

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/spf13/viper"
)

// Client keeps basic data to make a successful request to FBArchive service
type Client struct {
	httpClient *http.Client
	endpoint   string
}

// Error represents errors from FB Archive service
type Error struct {
	Errors interface{} `json:"errors"`
}

type GeoCodeInfo struct {
	Lat         string `json:"lat"`
	Lon         string `json:"lon"`
	DisplayName string `json:"display_name"`
	Address     struct {
		BusStop      string `json:"bus_stop"`
		Road         string `json:"road"`
		CityDistrict string `json:"city_district"`
		Hamlet       string `json:"hamlet"`
		Suburb       string `json:"suburb"`
		State        string `json:"state"`
		Postcode     string `json:"postcode"`
		Country      string `json:"country"`
		CountryCode  string `json:"country_code"`
	} `json:"address"`
	Boundingbox []string `json:"boundingbox"`
}

func (e *Error) Error() string {
	return fmt.Sprintf("%+v", e.Errors)
}

// NewClient creates new client to interact with FBArchive service
func NewClient(httpClient *http.Client) *Client {
	return &Client{
		httpClient: httpClient,
		endpoint:   viper.GetString("geoservice.endpoint"),
	}
}

func (c *Client) ReverseGeocode(ctx context.Context, lat, lon float64) (*GeoCodeInfo, error) {
	url := fmt.Sprintf("%s/reverse?lat=%f&lon=%f&format=json", c.endpoint, lat, lon)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Accept-Language", "en-US")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}

	decoder := json.NewDecoder(resp.Body)
	var respBody GeoCodeInfo

	if err := decoder.Decode(&respBody); err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	return &respBody, nil
}
