package main

import "time"

// startWeekday to find start time of the week of a given day
// timestamp is unix time in second
// weekday starts from Sunday
func startWeekday(timestamp int64) int64 {
	t := time.Unix(timestamp, 0)
	weekday := time.Duration(t.Weekday())
	year, month, day := t.Date()
	absDay := time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
	startWeekDay := absDay.Add(0 - weekday*time.Hour*24)
	return startWeekDay.Unix()
}
