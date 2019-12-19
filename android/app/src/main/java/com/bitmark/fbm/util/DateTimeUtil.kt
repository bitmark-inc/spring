/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util

import com.bitmark.fbm.data.model.entity.Period
import java.text.SimpleDateFormat
import java.util.*

class DateTimeUtil {

    companion object {

        val ISO8601_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"

        val ISO8601_SIMPLE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        val DATE_FORMAT_1 = "yyyy MMM dd HH:mm:ss"

        val DATE_FORMAT_2 = "yyyy MMM dd"

        val DATE_FORMAT_3 = "MMM dd"

        val DATE_FORMAT_4 = "EEEEE"

        val DATE_FORMAT_5 = "MMM"

        val DATE_FORMAT_6 = "ddd"

        val DATE_FORMAT_7 = "yyyy-MM-dd"

        val DATE_FORMAT_8 = "yyyy"

        val DATE_FORMAT_9 = "yyyy MMM"

        val DATE_FORMAT_10 = "EEE"

        val DATE_TIME_FORMAT_1 = "MMM dd hh:mm a"

        val TIME_FORMAT_1 = "hh:mm a"

        fun stringToString(date: String) =
            stringToString(date, DATE_FORMAT_1)

        fun stringToString(date: String, newFormat: String) =
            stringToString(date, ISO8601_FORMAT, newFormat)

        fun stringToString(
            date: String,
            oldFormat: String,
            newFormat: String,
            timezone: String = Calendar.getInstance().timeZone.id
        ): String {
            return try {
                var formatter = SimpleDateFormat(oldFormat, Locale.getDefault())
                formatter.timeZone = TimeZone.getTimeZone(timezone)
                val d = formatter.parse(date)
                formatter = SimpleDateFormat(newFormat, Locale.getDefault())
                formatter.format(d)
            } catch (e: Throwable) {
                ""
            }

        }

        fun dateToString(date: Date): String =
            dateToString(date, ISO8601_FORMAT)

        fun dateToString(
            date: Date,
            format: String,
            timezone: String = Calendar.getInstance().timeZone.id
        ): String {
            return try {
                val formatter = SimpleDateFormat(format, Locale.getDefault())
                formatter.timeZone = TimeZone.getTimeZone(timezone)
                formatter.format(date)
            } catch (e: Throwable) {
                ""
            }
        }

        fun stringToDate(date: String) = stringToDate(date, ISO8601_FORMAT)

        fun stringToDate(
            date: String,
            format: String,
            timezone: String = Calendar.getInstance().timeZone.id
        ): Date? {
            return try {
                val formatter = SimpleDateFormat(format, Locale.getDefault())
                formatter.timeZone = TimeZone.getTimeZone(timezone)
                formatter.parse(date)
            } catch (e: Throwable) {
                null
            }
        }

        fun dayCountFrom(date: Date): Long {
            val nowMillis = Date().time
            val diff = nowMillis - date.time
            return diff / (1000 * 60 * 60 * 24)
        }

        fun millisToString(millis: Long): String {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = millis
            return dateToString(calendar.time, ISO8601_FORMAT)
        }

        fun millisToString(
            millis: Long,
            format: String,
            timezone: String = Calendar.getInstance().timeZone.id
        ): String {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = millis
            return dateToString(calendar.time, format, timezone)
        }

        fun getThisYear() = Calendar.getInstance().get(Calendar.YEAR)

        fun getToday() = Calendar.getInstance().time

        fun getStartOfLastWeekMillis(): Long {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY)
            calendar.set(Calendar.WEEK_OF_YEAR, calendar.get(Calendar.WEEK_OF_YEAR) - 1)
            val startOfSunday = getStartOfDate(calendar)
            return startOfSunday.timeInMillis
        }

        fun getStartOfLastWeekMillis(thisWeekMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = thisWeekMillis
            calendar.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY)
            calendar.set(Calendar.WEEK_OF_YEAR, calendar.get(Calendar.WEEK_OF_YEAR) - 1)
            val startOfSunday = getStartOfDate(calendar)
            return startOfSunday.timeInMillis
        }

        fun getStartOfNextWeekMillis(thisWeekMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = thisWeekMillis
            calendar.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY)
            calendar.set(Calendar.WEEK_OF_YEAR, calendar.get(Calendar.WEEK_OF_YEAR) + 1)
            val startOfSunday = getStartOfDate(calendar)
            return startOfSunday.timeInMillis
        }

        fun getEndOfWeek(millis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = millis
            calendar.set(Calendar.DAY_OF_WEEK, Calendar.SATURDAY)
            return getEndOfDate(calendar).timeInMillis
        }

        fun getStartOfThisYearMillis(): Long {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            val startOfYear = getStartOfDate(calendar)
            return startOfYear.timeInMillis
        }

        fun getStartOfLastYearMillis(thisYearMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = thisYearMillis
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) - 1)
            val startOfYear = getStartOfDate(calendar)
            return startOfYear.timeInMillis
        }

        fun getStartOfNextYearMillis(thisYearMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = thisYearMillis
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) + 1)
            val startOfYear = getStartOfDate(calendar)
            return startOfYear.timeInMillis
        }

        fun getEndOfYear(millis: Long): Long {
            val nextYearMillis = getStartOfNextYearMillis(millis)
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = nextYearMillis
            calendar.set(Calendar.DAY_OF_YEAR, calendar.get(Calendar.DAY_OF_YEAR) - 1)
            return getEndOfDate(calendar).timeInMillis
        }

        fun getStartOfThisDecadeMillis(): Long {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) - 9)
            val startOfDecade = getStartOfDate(calendar)
            return startOfDecade.timeInMillis
        }

        fun getStartOfLastDecadeMillis(startOfThisDecadeMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = startOfThisDecadeMillis
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) - 10)
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            val startOfDecade = getStartOfDate(calendar)
            return startOfDecade.timeInMillis
        }

        fun getStartOfNextDecadeMillis(startOfThisDecadeMillis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = startOfThisDecadeMillis
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) + 10)
            calendar.set(Calendar.DAY_OF_YEAR, 1)
            val startOfDecade = getStartOfDate(calendar)
            return startOfDecade.timeInMillis
        }

        fun getEndOfDecade(startOfThisDecadeMillis: Long): Long {
            val nextDecadeMillis = getStartOfNextDecadeMillis(startOfThisDecadeMillis)
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = nextDecadeMillis
            calendar.set(Calendar.DAY_OF_YEAR, calendar.get(Calendar.DAY_OF_YEAR) - 1)
            return getEndOfDate(calendar).timeInMillis
        }

        fun getStartOfDate(calendar: Calendar): Calendar {
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            return calendar
        }

        fun getEndOfDate(millis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = millis
            return getEndOfDate(calendar).timeInMillis
        }

        fun getEndOfDate(calendar: Calendar): Calendar {
            calendar.set(Calendar.HOUR_OF_DAY, 23)
            calendar.set(Calendar.MINUTE, 59)
            calendar.set(Calendar.SECOND, 59)
            calendar.set(Calendar.MILLISECOND, 999)
            return calendar
        }

        fun getDateRangeOfWeek(startOfWeekMillis: Long): Pair<Date, Date> {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = startOfWeekMillis
            val startDate = getStartOfDate(calendar).time
            calendar.set(Calendar.WEEK_OF_YEAR, calendar.get(Calendar.WEEK_OF_YEAR) + 1)
            calendar.set(Calendar.DAY_OF_YEAR, calendar.get(Calendar.DAY_OF_YEAR) - 1)
            val endDate = getEndOfDate(calendar).time
            return Pair(startDate, endDate)
        }

        fun getDateRangeOfDecade(startOfDecadeMillis: Long): Pair<Date, Date> {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = startOfDecadeMillis
            val startDate = getStartOfDate(calendar).time
            calendar.set(Calendar.YEAR, calendar.get(Calendar.YEAR) + 9)
            val endDate = getEndOfDate(calendar).time
            return Pair(startDate, endDate)
        }

        fun getDoW(date: Date): Int {
            val calendar = Calendar.getInstance()
            calendar.time = date
            return calendar.get(Calendar.DAY_OF_WEEK)
        }

        fun getMoY(date: Date): Int {
            val calendar = Calendar.getInstance()
            calendar.time = date
            return calendar.get(Calendar.MONTH)
        }

        fun getYear(date: Date): Int {
            val calendar = Calendar.getInstance()
            calendar.time = date
            return calendar.get(Calendar.YEAR)
        }

        fun getEndOfMonth(millis: Long): Long {
            val calendar = Calendar.getInstance()
            calendar.timeInMillis = millis
            calendar.set(Calendar.MONTH, calendar.get(Calendar.MONTH) + 1)
            calendar.set(Calendar.DAY_OF_MONTH, 1)
            calendar.set(Calendar.DAY_OF_YEAR, calendar.get(Calendar.DAY_OF_YEAR) - 1)
            return getEndOfDate(calendar).timeInMillis
        }

    }
}

fun DateTimeUtil.Companion.formatPeriod(period: Period, startedTimeMillis: Long): String {
    val calendar = Calendar.getInstance()
    calendar.timeInMillis = startedTimeMillis
    return when (period) {
        Period.WEEK   -> {
            val range = getDateRangeOfWeek(startedTimeMillis)
            "%d %s-%s".format(
                getYear(calendar.time),
                dateToString(range.first, DATE_FORMAT_3),
                dateToString(range.second, DATE_FORMAT_3)
            )
        }
        Period.YEAR   -> {
            "%d".format(getYear(calendar.time))
        }
        Period.DECADE -> {
            val range = getDateRangeOfDecade(startedTimeMillis)
            "%s-%s".format(
                dateToString(range.first, DATE_FORMAT_8),
                dateToString(range.second, DATE_FORMAT_8)
            )
        }
    }
}

fun DateTimeUtil.Companion.formatSubPeriod(period: Period, startedTimeMillis: Long): String {
    val calendar = Calendar.getInstance()
    calendar.timeInMillis = startedTimeMillis
    return when (period) {
        Period.WEEK   -> millisToString(startedTimeMillis, DATE_FORMAT_10)
        Period.YEAR   -> millisToString(startedTimeMillis, DATE_FORMAT_9)
        Period.DECADE -> millisToString(startedTimeMillis, DATE_FORMAT_8)
    }
}