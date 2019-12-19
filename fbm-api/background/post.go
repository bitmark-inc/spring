package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httputil"

	"github.com/getsentry/sentry-go"
	"github.com/gocraft/work"
	log "github.com/sirupsen/logrus"
)

type postResult struct {
	AddressText     string   `json:"address_text,omitempty"`
	LatitudeNumber  float64  `json:"latitude_number,omitempty"`
	LocationText    string   `json:"location_text,omitempty"`
	LongitudeNumber float64  `json:"longitude_number,omitempty"`
	TagsListText    []string `json:"tags_list_text"`
	TimestampNumber int64    `json:"timestamp_number"`
	TypeText        string   `json:"type_text"`
	URLPlaceText    string   `json:"url_place_text"`
	PhotoText       string   `json:"photo_text"`
	VideoText       string   `json:"video_text"`
	ThumbnailText   string   `json:"thumbnail_text"`
	URLText         string   `json:"url_text"`
	TitleText       string   `json:"title_text"`
	PostText        string   `json:"post_text"`
	IDNumber        uint64   `json:"id_number"`
}

type postResponseData struct {
	Response struct {
		Count     int          `json:"count"`
		Cursor    int          `json:"cursor"`
		Remaining int          `json:"remaining"`
		Results   []postResult `json:"results"`
	} `json:"response"`
}

type mediaData struct {
	Type      string `json:"type"`
	Source    string `json:"source"`
	Thumbnail string `json:"thumbnail,omitempty"`
}

type postData struct {
	Timestamp int64       `json:"timestamp"`
	Type      string      `json:"type"`
	Post      string      `json:"post,omitempty"`
	ID        uint64      `json:"id"`
	Media     []mediaData `json:"mediaData,omitempty"`
	Location  string      `json:"location,omitempty"`
	URL       string      `json:"url,omitempty"`
	Title     string      `json:"title"`
	Tags      []string    `json:"tags,omitempty"`
}

type periodData struct {
	Name string         `json:"name"`
	Data map[string]int `json:"data"`
}

type statisticData struct {
	SectionName      string  `json:"section_name"`
	DiffFromPrevious float64 `json:"diff_from_previous"`
	Period           string  `json:"period"`
	PeriodStartedAt  int64   `json:"period_started_at"`
	Quantity         int     `json:"quantity"`
	Groups           struct {
		Type      map[string]int `json:"type"`
		SubPeriod []periodData   `json:"sub_period"`
		Friend    []periodData   `json:"friend"`
		Place     []periodData   `json:"place"`
	} `json:"groups,omitempty"`
}

func (b *BackgroundContext) extractPost(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	url := job.ArgString("url")
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	currentCursor := 0

	counter := newPostStatisticCounter()

	for {
		// Checking job
		job.Checkin(fmt.Sprintf("Fetching batch: %d", currentCursor))

		// Build url
		pagingURL := fmt.Sprintf("%s?cursor=%d", url, currentCursor)
		req, err := http.NewRequestWithContext(ctx, "GET", pagingURL, nil)
		if err != nil {
			logEntity.Error(err)
			return err
		}

		reqDump, err := httputil.DumpRequest(req, true)
		if err != nil {
			logEntity.Error(err)
		}
		logEntity.WithField("dump", string(reqDump)).Info("Request dump")

		resp, err := b.httpClient.Do(req)
		if err != nil {
			logEntity.Error(err)
			return err
		}

		// Print out the response in console log
		dumpBytes, err := httputil.DumpResponse(resp, false)
		if err != nil {
			logEntity.Error(err)
		}
		dump := string(dumpBytes)
		logEntity.Info("response: ", dump)

		if resp.StatusCode > 300 {
			logEntity.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
			return nil
		}

		job.Checkin("Parse data")
		decoder := json.NewDecoder(resp.Body)
		var respData postResponseData
		if err := decoder.Decode(&respData); err != nil {
			logEntity.Error("Request failed")
			sentry.CaptureException(errors.New("Request failed"))
		}

		// Save to db
		for _, r := range respData.Response.Results {
			postType := ""
			var media []mediaData
			switch r.TypeText {
			case "photo":
				postType = "media"
				media = []mediaData{
					mediaData{
						Type:      "photo",
						Source:    r.PhotoText,
						Thumbnail: r.PhotoText,
					},
				}
			case "video":
				postType = "media"
				media = []mediaData{
					mediaData{
						Type:      "video",
						Source:    r.VideoText,
						Thumbnail: r.ThumbnailText,
					},
				}
			case "text":
				postType = "update"
			case "link":
				postType = "link"
			default:
				continue
			}

			logEntity.Info("Processing post with timestamp: ", r.TimestampNumber)

			// Add post
			post := postData{
				Timestamp: r.TimestampNumber,
				Type:      postType,
				Post:      r.PostText,
				ID:        r.IDNumber,
				Media:     media,
				Location:  r.LocationText,
				URL:       r.URLText,
				Title:     r.TitleText,
				Tags:      r.TagsListText,
			}
			if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post", r.TimestampNumber, post); err != nil {
				logEntity.Error(err)
				sentry.CaptureException(err)
				continue
			}
			counter.countWeek(&post)
			counter.countYear(&post)
			counter.countDecade(&post)
		}

		// Should continue?
		if respData.Response.Remaining == 0 {
			break
		} else {
			currentCursor += respData.Response.Count
		}
	}

	logEntity.Info("Flushing...")
	// Force to flush current data
	counter.flushWeekData()
	counter.flushYearData()
	counter.flushDecadeData()

	// Save stats
	for _, weekStat := range counter.Weeks {
		logEntity.Info("Save week stat: ", weekStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/week-stat", weekStat.PeriodStartedAt, weekStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, yearStat := range counter.Years {
		logEntity.Info("Save year stat: ", yearStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/year-stat", yearStat.PeriodStartedAt, yearStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, decadeStat := range counter.Decades {
		logEntity.Info("Save decade stat: ", decadeStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/decade-stat", decadeStat.PeriodStartedAt, decadeStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}

	logEntity.Info("Finish...")

	return nil
}

type postStatisticCounter struct {
	Weeks   []statisticData
	Years   []statisticData
	Decades []statisticData

	WeekTypePeriodsMap   map[string]map[string]int
	YearTypePeriodsMap   map[string]map[string]int
	DecadeTypePeriodsMap map[string]map[string]int

	WeekFriendPeriodsMap   map[string]map[string]int
	YearFriendPeriodsMap   map[string]map[string]int
	DecadeFriendPeriodsMap map[string]map[string]int

	WeekPlacePeriodsMap   map[string]map[string]int
	YearPlacePeriodsMap   map[string]map[string]int
	DecadePlacePeriodsMap map[string]map[string]int

	// to cache the current week, year or decade
	currentWeek   int64
	currentYear   int64
	currentDecade int64

	// to count the type overral of a week, year or decade
	currentWeekTypeMap   map[string]int
	currentYearTypeMap   map[string]int
	currentDecadeTypeMap map[string]int

	lastTotalPostOfWeek   int
	lastTotalPostOfYear   int
	lastTotalPostOfDecade int
}

func plusOneValue(m *map[string]int, key string) {
	if v, ok := (*m)[key]; ok {
		(*m)[key] = v + 1
	} else {
		(*m)[key] = 1
	}
}

func addOneToArray(m *map[string]int, key string) {
	if v, ok := (*m)[key]; ok {
		(*m)[key] = v + 1
	} else {
		(*m)[key] = 1
	}
}

func getMap(m map[string]map[string]int, key string) *map[string]int {
	if v, ok := m[key]; ok {
		return &v
	}

	v := make(map[string]int)
	m[key] = v
	return &v
}

func newPostStatisticCounter() *postStatisticCounter {
	return &postStatisticCounter{
		WeekTypePeriodsMap:   make(map[string]map[string]int),
		YearTypePeriodsMap:   make(map[string]map[string]int),
		DecadeTypePeriodsMap: make(map[string]map[string]int),

		WeekFriendPeriodsMap:   make(map[string]map[string]int),
		YearFriendPeriodsMap:   make(map[string]map[string]int),
		DecadeFriendPeriodsMap: make(map[string]map[string]int),

		WeekPlacePeriodsMap:   make(map[string]map[string]int),
		YearPlacePeriodsMap:   make(map[string]map[string]int),
		DecadePlacePeriodsMap: make(map[string]map[string]int),

		currentWeekTypeMap:   make(map[string]int),
		currentYearTypeMap:   make(map[string]int),
		currentDecadeTypeMap: make(map[string]int),

		Weeks:   make([]statisticData, 0),
		Years:   make([]statisticData, 0),
		Decades: make([]statisticData, 0),
	}
}

func (sc *postStatisticCounter) flushWeekData() {
	// Sub periods
	subPeriods := make([]periodData, 0)
	for name, dayData := range sc.WeekTypePeriodsMap {
		subPeriods = append(subPeriods, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Friends
	friends := make([]periodData, 0)
	for name, dayData := range sc.WeekFriendPeriodsMap {
		friends = append(friends, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Places
	places := make([]periodData, 0)
	for name, dayData := range sc.WeekPlacePeriodsMap {
		places = append(places, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Count the difference with last period
	currentTotal := 0
	for _, count := range sc.currentWeekTypeMap {
		currentTotal += count
	}
	difference := 1.0
	if sc.lastTotalPostOfWeek > 0 {
		difference = float64((currentTotal - sc.lastTotalPostOfWeek)) / float64(sc.lastTotalPostOfWeek)
	}

	weekStatisticData := statisticData{
		SectionName:      "post",
		Period:           "week",
		PeriodStartedAt:  sc.currentWeek,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      map[string]int `json:"type"`
			SubPeriod []periodData   `json:"sub_period"`
			Friend    []periodData   `json:"friend"`
			Place     []periodData   `json:"place"`
		}{
			Type:      sc.currentWeekTypeMap,
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Weeks = append(sc.Weeks, weekStatisticData)

	// Clean obsolete data
	sc.WeekTypePeriodsMap = make(map[string]map[string]int)
	sc.WeekFriendPeriodsMap = make(map[string]map[string]int)
	sc.WeekPlacePeriodsMap = make(map[string]map[string]int)
	sc.currentWeekTypeMap = make(map[string]int)
}

func (sc *postStatisticCounter) countWeek(r *postData) {
	week := absWeekday(r.Timestamp)
	if sc.currentWeek == 0 {
		sc.currentWeek = week
	}

	if week > sc.currentWeek {
		// Flush data
		sc.flushWeekData()

		// Set current week
		sc.currentWeek = week
	}

	// parse sub periods of days, friends, places in a week
	plusOneValue(&sc.currentWeekTypeMap, r.Type)
	weekTypeMap := getMap(sc.WeekTypePeriodsMap, timestampToDateString(absDay(r.Timestamp)))
	plusOneValue(weekTypeMap, r.Type)
	sc.lastTotalPostOfWeek++

	if r.Location != "" {
		weekPlaceMap := getMap(sc.WeekPlacePeriodsMap, r.Location)
		plusOneValue(weekPlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		weekFriendMap := getMap(sc.WeekFriendPeriodsMap, f)
		plusOneValue(weekFriendMap, r.Type)
	}
}

func (sc *postStatisticCounter) flushYearData() {
	// Sub periods
	subPeriods := make([]periodData, 0)
	for name, dayData := range sc.YearTypePeriodsMap {
		subPeriods = append(subPeriods, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Friends
	friends := make([]periodData, 0)
	for name, dayData := range sc.YearFriendPeriodsMap {
		friends = append(friends, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Places
	places := make([]periodData, 0)
	for name, dayData := range sc.YearPlacePeriodsMap {
		places = append(places, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Count the difference with last period
	currentTotal := 0
	for _, count := range sc.currentYearTypeMap {
		currentTotal += count
	}
	difference := 1.0
	if sc.lastTotalPostOfYear > 0 {
		difference = float64((currentTotal - sc.lastTotalPostOfYear)) / float64(sc.lastTotalPostOfYear)
	}

	yearStatisticData := statisticData{
		SectionName:      "post",
		Period:           "year",
		PeriodStartedAt:  sc.currentYear,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      map[string]int `json:"type"`
			SubPeriod []periodData   `json:"sub_period"`
			Friend    []periodData   `json:"friend"`
			Place     []periodData   `json:"place"`
		}{
			Type:      sc.currentYearTypeMap,
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Years = append(sc.Years, yearStatisticData)

	// Clean obsolete data
	sc.YearTypePeriodsMap = make(map[string]map[string]int)
	sc.YearFriendPeriodsMap = make(map[string]map[string]int)
	sc.YearPlacePeriodsMap = make(map[string]map[string]int)
	sc.currentYearTypeMap = make(map[string]int)
}

func (sc *postStatisticCounter) countYear(r *postData) {
	year := absYear(r.Timestamp)
	if sc.currentYear == 0 {
		sc.currentYear = year
	}

	if year > sc.currentYear {
		// Flush data
		sc.flushYearData()

		// Set current year
		sc.currentYear = year
	}

	// parse sub periods of days, friends, places in a year
	plusOneValue(&sc.currentWeekTypeMap, r.Type)
	yearTypeMap := getMap(sc.WeekTypePeriodsMap, timestampToDateString(absMonth(r.Timestamp)))
	plusOneValue(yearTypeMap, r.Type)
	sc.lastTotalPostOfWeek++

	if r.Location != "" {
		yearPlaceMap := getMap(sc.WeekPlacePeriodsMap, r.Location)
		plusOneValue(yearPlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		yearFriendMap := getMap(sc.WeekFriendPeriodsMap, f)
		plusOneValue(yearFriendMap, r.Type)
	}
}

func (sc *postStatisticCounter) flushDecadeData() {
	// Sub periods
	subPeriods := make([]periodData, 0)
	for name, dayData := range sc.DecadeTypePeriodsMap {
		subPeriods = append(subPeriods, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Friends
	friends := make([]periodData, 0)
	for name, dayData := range sc.DecadeFriendPeriodsMap {
		friends = append(friends, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Places
	places := make([]periodData, 0)
	for name, dayData := range sc.DecadePlacePeriodsMap {
		places = append(places, periodData{
			Name: name,
			Data: dayData,
		})
	}

	// Count the difference with last period
	currentTotal := 0
	for _, count := range sc.currentDecadeTypeMap {
		currentTotal += count
	}
	difference := 1.0
	if sc.lastTotalPostOfDecade > 0 {
		difference = float64((currentTotal - sc.lastTotalPostOfDecade)) / float64(sc.lastTotalPostOfDecade)
	}

	decadeStatisticData := statisticData{
		SectionName:      "post",
		Period:           "decade",
		PeriodStartedAt:  sc.currentDecade,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      map[string]int `json:"type"`
			SubPeriod []periodData   `json:"sub_period"`
			Friend    []periodData   `json:"friend"`
			Place     []periodData   `json:"place"`
		}{
			Type:      sc.currentDecadeTypeMap,
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Decades = append(sc.Decades, decadeStatisticData)

	// Clean obsolete data
	sc.DecadeTypePeriodsMap = make(map[string]map[string]int)
	sc.DecadeFriendPeriodsMap = make(map[string]map[string]int)
	sc.DecadePlacePeriodsMap = make(map[string]map[string]int)
	sc.currentDecadeTypeMap = make(map[string]int)
}

func (sc *postStatisticCounter) countDecade(r *postData) {
	decade := absDecade(r.Timestamp)
	if sc.currentDecade == 0 {
		sc.currentDecade = decade
	}

	if decade > sc.currentDecade {
		// Flush data
		sc.flushDecadeData()

		// Set current decade
		sc.currentDecade = decade
	}

	// parse sub periods of days, friends, places in a decade
	plusOneValue(&sc.currentDecadeTypeMap, r.Type)
	decadeTypeMap := getMap(sc.DecadeTypePeriodsMap, timestampToDateString(absYear(r.Timestamp)))
	plusOneValue(decadeTypeMap, r.Type)
	sc.lastTotalPostOfDecade++

	if r.Location != "" {
		decadePlaceMap := getMap(sc.DecadePlacePeriodsMap, r.Location)
		plusOneValue(decadePlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		decadeFriendMap := getMap(sc.DecadeFriendPeriodsMap, f)
		plusOneValue(decadeFriendMap, r.Type)
	}
}
