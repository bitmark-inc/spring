/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util

import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

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

        val DATE_TIME_FORMAT_1 = "MMM dd hh:mm a"

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

        fun getStartOfDate(calendar: Calendar): Calendar {
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            return calendar
        }

        fun getEndOfDate(calendar: Calendar): Calendar {
            calendar.set(Calendar.HOUR_OF_DAY, 23)
            calendar.set(Calendar.MINUTE, 59)
            calendar.set(Calendar.SECOND, 59)
            calendar.set(Calendar.MILLISECOND, 999)
            return calendar
        }

        fun getDateRangeOfWeek(numWeekFromNow: Int): Pair<Date, Date> {
            val startDate = Calendar.getInstance()
            startDate.set(
                Calendar.WEEK_OF_YEAR,
                startDate.get(Calendar.WEEK_OF_YEAR) + numWeekFromNow
            )
            val endDate = Calendar.getInstance()
            endDate.set(Calendar.WEEK_OF_YEAR, endDate.get(Calendar.WEEK_OF_YEAR) + numWeekFromNow)
            startDate.set(Calendar.DAY_OF_WEEK, Calendar.SUNDAY)
            endDate.set(Calendar.DAY_OF_WEEK, Calendar.SATURDAY)
            return Pair(getStartOfDate(startDate).time, getEndOfDate(endDate).time)
        }

        fun getYearFromNowWithGap(gap: Int): IntArray {
            val years = IntArray(abs(gap))
            val calendar = Calendar.getInstance()
            years[if (gap > 0) 0 else years.size - 1] = calendar.get(Calendar.YEAR)
            var count = 1

            while (count < years.size) {
                val currentYear = calendar.get(Calendar.YEAR)
                calendar.set(Calendar.YEAR, if (gap > 0) currentYear + 1 else currentYear - 1)
                val index = if (gap > 0) count else years.size - count - 1
                years[index] = calendar.get(Calendar.YEAR)
                count++
            }
            return years
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

        fun getYear(date: Date) : Int {
            val calendar = Calendar.getInstance()
            calendar.time = date
            return calendar.get(Calendar.YEAR)
        }
    }
}