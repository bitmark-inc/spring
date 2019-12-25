package main

import (
	"context"
	"math/rand"
	"strconv"
	"time"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"
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

type mediaData struct {
	Type      string `json:"type"`
	Source    string `json:"source"`
	Thumbnail string `json:"thumbnail,omitempty"`
}

type locationData struct {
	Address    string `json:"address"`
	Coordinate struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	} `json:"coordinate"`
	URL       string `json:"url"`
	Name      string `json:"name"`
	CreatedAt int64  `json:"created_at"`
}

type friendData struct {
	ID   uint64 `json:"id"`
	Name string `json:"name"`
}

type postData struct {
	Timestamp int64         `json:"timestamp"`
	Type      string        `json:"type"`
	Post      string        `json:"post,omitempty"`
	ID        uint64        `json:"id"`
	Media     []mediaData   `json:"mediaData,omitempty"`
	Location  *locationData `json:"location,omitempty"`
	URL       string        `json:"url,omitempty"`
	Title     string        `json:"title"`
	Tags      []friendData  `json:"tags,omitempty"`
}

type periodData struct {
	Name string         `json:"name,omitempty"`
	Data map[string]int `json:"data"`
}

type statisticData struct {
	SectionName      string  `json:"section_name"`
	DiffFromPrevious float64 `json:"diff_from_previous"`
	Period           string  `json:"period"`
	PeriodStartedAt  int64   `json:"period_started_at"`
	Quantity         int     `json:"quantity"`
	Value            float64 `json:"value"`
	Groups           struct {
		Type      periodData   `json:"type"`
		SubPeriod []periodData `json:"sub_period"`
		Friend    []periodData `json:"friend"`
		Place     []periodData `json:"place"`
	} `json:"groups,omitempty"`
}

func randomSentiment() int {
	possibility := rand.Intn(9) + 1
	if possibility <= 7 {
		return rand.Intn(4) + 1
	} else {
		return rand.Intn(4) + 6
	}
}

func (b *BackgroundContext) extractPost(job *work.Job) error {
	logEntity := log.WithField("prefix", job.Name+"/"+job.ID)
	accountNumber := job.ArgString("account_number")
	if err := job.ArgError(); err != nil {
		return err
	}

	ctx := context.Background()

	counter := newPostStatisticCounter()
	currentOffset := 0

	for {
		postRespData, err := b.bitSocialClient.GetPosts(ctx, accountNumber, currentOffset)
		if err != nil {
			return err
		}

		logEntity.Info("Getting page offset: ", currentOffset)

		// Save to db
		for _, r := range postRespData.Results {
			postType := ""
			media := make([]mediaData, 0)

			if r.MediaAttached {
				postType = "media"
				for _, m := range r.Media {
					mediaType := "photo"
					if m.FilenameExtension == ".mp4" {
						mediaType = "video"
					}
					media = append(media, mediaData{
						Type:      mediaType,
						Source:    m.MediaURI,
						Thumbnail: m.ThumbnailURI,
					})
				}
			} else if r.ExternalContextURL != "" {
				postType = "link"
			} else if r.Post != "" {
				postType = "update"
			} else {
				continue
			}

			logEntity.Info("Processing post with timestamp: ", r.Timestamp)

			var l *locationData
			if len(r.Place) > 0 {
				firstPlace := r.Place[0]
				lat, _ := strconv.ParseFloat(firstPlace.Latitude, 64)
				long, _ := strconv.ParseFloat(firstPlace.Longitude, 64)
				l = &locationData{
					Address: firstPlace.Place,
					Coordinate: struct {
						Latitude  float64 `json:"latitude"`
						Longitude float64 `json:"longitude"`
					}{
						Latitude:  lat,
						Longitude: long,
					},
					Name:      firstPlace.Place,
					CreatedAt: r.Timestamp,
				}

				counter.lastLocation = l
			}

			friends := make([]friendData, 0)
			for _, f := range r.Tags {
				friends = append(friends, friendData{
					ID:   f.FriendID,
					Name: f.FriendName,
				})
			}

			// Add post
			post := postData{
				Timestamp: r.Timestamp,
				Type:      postType,
				Post:      r.Post,
				ID:        r.PostID,
				Media:     media,
				Location:  l,
				URL:       r.ExternalContextURL,
				Title:     r.Title,
				Tags:      friends,
			}
			if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post", r.Timestamp, post); err != nil {
				logEntity.Error(err)
				sentry.CaptureException(err)
				continue
			}
			counter.countWeek(&post)
			counter.countYear(&post)
			counter.countDecade(&post)

			if counter.earliestPostTimestamp > post.Timestamp {
				counter.earliestPostTimestamp = post.Timestamp
			}
		}

		// Should go to next page?
		total := len(postRespData.Results)
		if total == 0 {
			break
		} else {
			currentOffset += total
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
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post-week-stat", weekStat.PeriodStartedAt, weekStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, yearStat := range counter.Years {
		logEntity.Info("Save year stat: ", yearStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post-year-stat", yearStat.PeriodStartedAt, yearStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, decadeStat := range counter.Decades {
		logEntity.Info("Save decade stat: ", decadeStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/post-decade-stat", decadeStat.PeriodStartedAt, decadeStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}

	// Save sentiment
	for _, weekStat := range counter.SentimentWeeks {
		logEntity.Info("Save week stat: ", weekStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/sentiment-week-stat", weekStat.PeriodStartedAt, weekStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, yearStat := range counter.SentimentYears {
		logEntity.Info("Save year stat: ", yearStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/sentiment-year-stat", yearStat.PeriodStartedAt, yearStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}
	for _, decadeStat := range counter.SentimentDecades {
		logEntity.Info("Save decade stat: ", decadeStat.PeriodStartedAt)
		if err := b.fbDataStore.AddFBStat(ctx, accountNumber+"/sentiment-decade-stat", decadeStat.PeriodStartedAt, decadeStat); err != nil {
			logEntity.Error(err)
			sentry.CaptureException(err)
			continue
		}
	}

	logEntity.Info("Parsing location")
	// Calculate original location
	geoCodingData, err := b.geoServiceClient.ReverseGeocode(ctx,
		counter.lastLocation.Coordinate.Latitude,
		counter.lastLocation.Coordinate.Longitude)
	if err != nil {
		return err
	}

	logEntity.Info("Update to db with account number: ", accountNumber)
	// Get user and update
	if _, err := b.store.UpdateAccountMetadata(ctx, &store.AccountQueryParam{
		AccountNumber: &accountNumber,
	}, map[string]interface{}{
		"original_location":  geoCodingData.Address.CountryCode,
		"original_timestamp": counter.earliestPostTimestamp,
	}); err != nil {
		return err
	}

	logEntity.Info("Finish...")

	return nil
}

type postStatisticCounter struct {
	Weeks   []statisticData
	Years   []statisticData
	Decades []statisticData

	SentimentWeeks   []statisticData
	SentimentYears   []statisticData
	SentimentDecades []statisticData

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

	// to cache the last period timestamp
	lastWeek   int64
	lastYear   int64
	lastDecade int64

	// to count the type overral of a week, year or decade
	currentWeekTypeMap   map[string]int
	currentYearTypeMap   map[string]int
	currentDecadeTypeMap map[string]int

	// to cache the total post of last period
	lastTotalPostOfWeek   int
	lastTotalPostOfYear   int
	lastTotalPostOfDecade int

	// to cache the sentiment of the last period
	lastSentimentOfWeek   int
	lastSentimentOfYear   int
	lastSentimentOfDecade int

	lastLocation          *locationData
	earliestPostTimestamp int64
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

		lastLocation:          nil,
		earliestPostTimestamp: time.Now().Unix(),
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

	// Calculate the current total
	currentTotal := 0
	for _, count := range sc.currentWeekTypeMap {
		currentTotal += count
	}

	// Calculate the difference if last week has data
	difference := 1.0
	if sc.lastWeek == absWeek(sc.currentWeek-1) {
		difference = getDiff(uint64(currentTotal), uint64(sc.lastTotalPostOfWeek))
	}
	sc.lastTotalPostOfWeek = currentTotal

	weekStatisticData := statisticData{
		SectionName:      "post",
		Period:           "week",
		Quantity:         currentTotal,
		PeriodStartedAt:  sc.currentWeek,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      periodData   `json:"type"`
			SubPeriod []periodData `json:"sub_period"`
			Friend    []periodData `json:"friend"`
			Place     []periodData `json:"place"`
		}{
			Type: periodData{
				Data: sc.currentWeekTypeMap,
			},
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Weeks = append(sc.Weeks, weekStatisticData)

	// TODO: FIX THIS TO REAL SENTIMENT
	// calculate the current sentiment value
	currentSentiment := randomSentiment()
	//calculate the difference of sentiment if last week has data
	sentimentDifference := 1.0
	if sc.lastWeek == absWeek(sc.currentWeek-1) {
		sentimentDifference = getDiff(uint64(currentSentiment), uint64(sc.lastSentimentOfWeek))
	}
	sc.lastSentimentOfWeek = currentSentiment

	sentimentStatisticData := statisticData{
		SectionName:      "sentiment",
		Period:           "week",
		PeriodStartedAt:  sc.currentWeek,
		DiffFromPrevious: sentimentDifference,
		Value:            float64(currentSentiment),
	}
	sc.SentimentWeeks = append(sc.SentimentWeeks, sentimentStatisticData)

	// Clean obsolete data
	sc.WeekTypePeriodsMap = make(map[string]map[string]int)
	sc.WeekFriendPeriodsMap = make(map[string]map[string]int)
	sc.WeekPlacePeriodsMap = make(map[string]map[string]int)
	sc.currentWeekTypeMap = make(map[string]int)
}

func (sc *postStatisticCounter) countWeek(r *postData) {
	week := absWeek(r.Timestamp)
	if sc.currentWeek == 0 {
		sc.lastWeek = 0
		sc.currentWeek = week
	}

	if week != sc.currentWeek {
		// Flush data
		sc.flushWeekData()

		// Set current week
		sc.lastWeek = sc.currentWeek
		sc.currentWeek = week
	}

	// parse sub periods of days, friends, places in a week
	plusOneValue(&sc.currentWeekTypeMap, r.Type)
	weekTypeMap := getMap(sc.WeekTypePeriodsMap, strconv.FormatInt(absDay(r.Timestamp), 10))
	plusOneValue(weekTypeMap, r.Type)
	sc.lastTotalPostOfWeek++

	if r.Location != nil {
		weekPlaceMap := getMap(sc.WeekPlacePeriodsMap, r.Location.Name)
		plusOneValue(weekPlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		weekFriendMap := getMap(sc.WeekFriendPeriodsMap, f.Name)
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

	// Calculate the difference if last week has data
	difference := 1.0
	if sc.lastYear == absYear(sc.currentYear-1) {
		difference = getDiff(uint64(currentTotal), uint64(sc.lastTotalPostOfYear))
	}
	sc.lastTotalPostOfYear = currentTotal

	yearStatisticData := statisticData{
		SectionName:      "post",
		Period:           "year",
		Quantity:         currentTotal,
		PeriodStartedAt:  sc.currentYear,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      periodData   `json:"type"`
			SubPeriod []periodData `json:"sub_period"`
			Friend    []periodData `json:"friend"`
			Place     []periodData `json:"place"`
		}{
			Type: periodData{
				Data: sc.currentYearTypeMap,
			},
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Years = append(sc.Years, yearStatisticData)

	// TODO: FIX THIS TO REAL SENTIMENT
	// calculate the current sentiment value
	currentSentiment := randomSentiment()
	//calculate the difference of sentiment if last week has data
	sentimentDifference := 1.0
	if sc.lastYear == absYear(sc.currentYear-1) {
		sentimentDifference = getDiff(uint64(currentSentiment), uint64(sc.lastSentimentOfYear))
	}
	sc.lastSentimentOfYear = currentSentiment

	sentimentStatisticData := statisticData{
		SectionName:      "sentiment",
		Period:           "year",
		PeriodStartedAt:  sc.currentYear,
		DiffFromPrevious: sentimentDifference,
		Value:            float64(currentSentiment),
	}
	sc.SentimentYears = append(sc.SentimentYears, sentimentStatisticData)

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

	if year != sc.currentYear {
		// Flush data
		sc.flushYearData()

		// Set current year
		sc.currentYear = year
	}

	// parse sub periods of days, friends, places in a year
	plusOneValue(&sc.currentYearTypeMap, r.Type)
	yearTypeMap := getMap(sc.YearTypePeriodsMap, strconv.FormatInt(absMonth(r.Timestamp), 10))
	plusOneValue(yearTypeMap, r.Type)
	sc.lastTotalPostOfYear++

	if r.Location != nil {
		yearPlaceMap := getMap(sc.YearPlacePeriodsMap, r.Location.Name)
		plusOneValue(yearPlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		yearFriendMap := getMap(sc.YearFriendPeriodsMap, f.Name)
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

	// Calculate the difference if last week has data
	difference := 1.0
	if sc.lastDecade == absDecade(sc.currentDecade-1) {
		difference = getDiff(uint64(currentTotal), uint64(sc.lastTotalPostOfDecade))
	}
	sc.lastTotalPostOfDecade = currentTotal

	decadeStatisticData := statisticData{
		SectionName:      "post",
		Period:           "decade",
		Quantity:         currentTotal,
		PeriodStartedAt:  sc.currentDecade,
		DiffFromPrevious: difference,
		Groups: struct {
			Type      periodData   `json:"type"`
			SubPeriod []periodData `json:"sub_period"`
			Friend    []periodData `json:"friend"`
			Place     []periodData `json:"place"`
		}{
			Type: periodData{
				Data: sc.currentDecadeTypeMap,
			},
			SubPeriod: subPeriods,
			Friend:    friends,
			Place:     places,
		},
	}

	sc.Decades = append(sc.Decades, decadeStatisticData)

	// TODO: FIX THIS TO REAL SENTIMENT
	// calculate the current sentiment value
	currentSentiment := randomSentiment()
	//calculate the difference of sentiment if last week has data
	sentimentDifference := 1.0
	if sc.lastDecade == absDecade(sc.currentDecade-1) {
		sentimentDifference = getDiff(uint64(currentSentiment), uint64(sc.lastSentimentOfDecade))
	}
	sc.lastSentimentOfDecade = currentSentiment

	sentimentStatisticData := statisticData{
		SectionName:      "sentiment",
		Period:           "decade",
		PeriodStartedAt:  sc.currentDecade,
		DiffFromPrevious: sentimentDifference,
		Value:            float64(currentSentiment),
	}
	sc.SentimentDecades = append(sc.SentimentDecades, sentimentStatisticData)

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

	if decade != sc.currentDecade {
		// Flush data
		sc.flushDecadeData()

		// Set current decade
		sc.currentDecade = decade
	}

	// parse sub periods of days, friends, places in a decade
	plusOneValue(&sc.currentDecadeTypeMap, r.Type)
	decadeTypeMap := getMap(sc.DecadeTypePeriodsMap, strconv.FormatInt(absYear(r.Timestamp), 10))
	plusOneValue(decadeTypeMap, r.Type)
	sc.lastTotalPostOfDecade++

	if r.Location != nil {
		decadePlaceMap := getMap(sc.DecadePlacePeriodsMap, r.Location.Name)
		plusOneValue(decadePlaceMap, r.Type)
	}

	for _, f := range r.Tags {
		decadeFriendMap := getMap(sc.DecadeFriendPeriodsMap, f.Name)
		plusOneValue(decadeFriendMap, r.Type)
	}
}
