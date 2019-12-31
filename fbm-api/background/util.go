package main

import (
	"context"

	"github.com/bitmark-inc/fbm-apps/fbm-api/store"

	"time"
)

// absDay to find start time of the week of a given time
// timestamp is unix time in second
// days start from 12:00 AM
func absDay(timestamp int64) int64 {
	t := time.Unix(timestamp, 0).UTC()
	year, month, day := t.Date()
	absDay := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absWeek to find start time of the week of a given time
// timestamp is unix time in second
// weekdays start from Sunday
func absWeek(timestamp int64) int64 {
	t := time.Unix(timestamp, 0).UTC()
	weekday := time.Duration(t.Weekday())
	year, month, day := t.Date()
	absDay := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	startWeekDay := absDay.Add(0 - weekday*time.Hour*24)
	return startWeekDay.Unix()
}

// absMonth to find start time of the month of a given time
// timestamp is unix time in second
// days start from 12:00 AM
func absMonth(timestamp int64) int64 {
	t := time.Unix(timestamp, 0).UTC()
	year, month, _ := t.Date()
	absDay := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absYear to find start time of the year of a given time
// timestamp is unix time in second
// years start from Jan 1st
func absYear(timestamp int64) int64 {
	t := time.Unix(timestamp, 0).UTC()
	year := t.Year()
	absDay := time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absDecade to find start time of the decade of a given time
// timestamp is unix time in second
func absDecade(timestamp int64) int64 {
	t := time.Unix(timestamp, 0).UTC()
	year := t.Year()
	absYear := year % 10
	absDay := time.Date(year-absYear, 1, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absPeriod find start time of the period in seconds
func absPeriod(period string, timestamp int64) int64 {
	switch period {
	case "week":
		return absWeek(timestamp)
	case "month":
		return absMonth(timestamp)
	case "year":
		return absYear(timestamp)
	case "decade":
		return absDecade(timestamp)
	default:
		return timestamp
	}
}

func timestampToDateString(timestamp int64) string {
	t := time.Unix(timestamp, 0).UTC()
	return t.Format("2006-01-02")
}

func getDiff(current, last float64) float64 {
	var difference float64
	if last != 0 {
		difference = (current - last) / last
	} else if current == 0 {
		difference = 0
	} else {
		difference = 1
	}
	return difference
}

type statSaver struct {
	store store.FBDataStore
	queue []store.FBStat
}

func newStatSaver(fbstore store.FBDataStore) *statSaver {
	return &statSaver{
		store: fbstore,
		queue: make([]store.FBStat, 0),
	}
}

func (s *statSaver) save(key string, timestamp int64, value interface{}) error {
	s.queue = append(s.queue, store.FBStat{
		Key:       key,
		Timestamp: timestamp,
		Value:     value,
	})

	if len(s.queue) < 25 {
		return nil
	}

	if err := s.flush(); err != nil {
		return err
	}

	s.queue = make([]store.FBStat, 0)
	return nil
}

func (s *statSaver) flush() error {
	ctx := context.Background()
	if len(s.queue) > 0 {
		err := s.store.AddFBStats(ctx, s.queue)
		return err
	}
	return nil
}
