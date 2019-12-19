package main

import "time"

// absWeekday to find start time of the week of a given day
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

// absYear to find start time of the year of a given day
// timestamp is unix time in second
// years start from Jan 1st
func absYear(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	year := t.Year()
	absDay := time.Date(year, 0, 0, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}

// absDecade to find start time of the decade of a given day
// timestamp is unix time in second
func absDecade(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	year := t.Year()
	absYear := year % 10
	absDay := time.Date(absYear, 0, 0, 0, 0, 0, 0, time.UTC)
	return absDay.Unix()
}
