package main

import "time"

// absDay to find start time of the week of a given time
// timestamp is unix time in second
// days start from 12:00 AM
func absDay(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	year, month, day := t.Date()
	absDay := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absWeekday to find start time of the week of a given time
// timestamp is unix time in second
// weekdays start from Sunday
func absWeekday(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
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
	t := time.Unix(timestamp, 0)
	year, month, _ := t.Date()
	absDay := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absYear to find start time of the year of a given time
// timestamp is unix time in second
// years start from Jan 1st
func absYear(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	year := t.Year()
	absDay := time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absDecade to find start time of the decade of a given time
// timestamp is unix time in second
func absDecade(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	year := t.Year()
	absYear := year % 10
	absDay := time.Date(absYear, 1, 1, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

func timestampToDateString(timestamp int64) string {
	t := time.Unix(timestamp, 0)
	return t.Format("2006-01-02")
}
