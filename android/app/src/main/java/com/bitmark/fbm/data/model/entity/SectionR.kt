/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.bitmark.fbm.util.DateTimeUtil
import com.google.gson.Gson
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Section",
    indices = [Index(value = ["period_started_at"]), Index(value = ["id"], unique = true)]
)
data class SectionR(

    @Expose
    @SerializedName("id")
    @ColumnInfo(name = "id")
    @PrimaryKey(autoGenerate = true)
    val id: Long,

    @Expose
    @SerializedName("section_name")
    @ColumnInfo(name = "section_name")
    val name: SectionName,

    @Expose
    @SerializedName("period")
    @ColumnInfo(name = "period")
    val period: Period,

    @Expose
    @SerializedName("period_started_at")
    @ColumnInfo(name = "period_started_at")
    val periodStartedAtSec: Long,

    @Expose
    @SerializedName("diff_from_previous")
    @ColumnInfo(name = "diff_from_previous")
    val diffFromPrev: Float,

    @Expose
    @SerializedName("quantity")
    @ColumnInfo(name = "quantity")
    val quantity: Int,

    @Expose
    @SerializedName("groups")
    @ColumnInfo(name = "groups")
    val groups: Map<String, Any>?,

    @Expose
    @SerializedName("value")
    @ColumnInfo(name = "value")
    val value: Float?
) : Record

inline fun <reified T> SectionR.getGroup(g: GroupName): T {
    val gson = Gson().newBuilder().create()
    val group = groups?.get(g.value) ?: error("${g.value} is not existing")
    val json = gson.toJson(group)
    return gson.fromJson(json, T::class.java)
}

inline fun <reified T> SectionR.getArrayGroup(g: GroupName): List<T> {
    val gson = Gson().newBuilder().create()
    val group = groups?.get(g.value) ?: error("${g.value} is not existing")
    if (group !is List<*>) error("not a list")
    val result = mutableListOf<T>()
    group.forEach { g ->
        result.add(gson.fromJson(gson.toJson(g), T::class.java))
    }
    return result
}

enum class SectionName {
    @Expose
    @SerializedName("post")
    POST,

    @Expose
    @SerializedName("reaction")
    REACTION,

    @Expose
    @SerializedName("messages")
    MESSAGE,

    @Expose
    @SerializedName("ad_interests")
    AD_INTEREST,

    @Expose
    @SerializedName("advertisers")
    ADVERTISER,

    @Expose
    @SerializedName("locations")
    LOCATION,

    @Expose
    @SerializedName("fb-income")
    FB_INCOME,

    @Expose
    @SerializedName("sentiment")
    SENTIMENT;

    companion object
}

fun SectionName.Companion.fromString(name: String) = when (name) {
    "post"         -> SectionName.POST
    "reaction"     -> SectionName.REACTION
    "messages"     -> SectionName.MESSAGE
    "ad_interests" -> SectionName.AD_INTEREST
    "advertisers"  -> SectionName.ADVERTISER
    "locations"    -> SectionName.LOCATION
    "fb-income"    -> SectionName.FB_INCOME
    "sentiment"    -> SectionName.SENTIMENT
    else           -> error("invalid name")
}

val SectionName.value: String
    get() = when (this) {
        SectionName.POST        -> "post"
        SectionName.REACTION    -> "reaction"
        SectionName.MESSAGE     -> "messages"
        SectionName.AD_INTEREST -> "ad_interests"
        SectionName.ADVERTISER  -> "advertisers"
        SectionName.LOCATION    -> "locations"
        SectionName.SENTIMENT   -> "sentiment"
        SectionName.FB_INCOME   -> "fb-income"
    }

data class GroupEntity(
    @Expose
    @SerializedName("name")
    val name: String,

    @Expose
    @SerializedName("data")
    val data: Map<String, Int>
) : Record

fun GroupEntity.sum() = data.entries.sumBy { e -> e.value }

enum class GroupName {
    TYPE,
    SUB_PERIOD,
    FRIEND,
    PLACE,
    AREA;

    companion object
}

val GroupName.value: String
    get() = when (this) {
        GroupName.TYPE       -> "type"
        GroupName.SUB_PERIOD -> "sub_period"
        GroupName.FRIEND     -> "friend"
        GroupName.PLACE      -> "place"
        GroupName.AREA       -> "area"
    }

fun GroupName.Companion.fromString(name: String) = when (name) {
    "type"       -> GroupName.TYPE
    "sub_period" -> GroupName.SUB_PERIOD
    "friend"     -> GroupName.FRIEND
    "place"      -> GroupName.PLACE
    "area"       -> GroupName.AREA
    else         -> error("invalid group name")
}

enum class Period {
    @Expose
    @SerializedName("week")
    WEEK,

    @Expose
    @SerializedName("year")
    YEAR,

    @Expose
    @SerializedName("decade")
    DECADE;

    companion object
}

fun Period.Companion.fromString(period: String) = when (period) {
    "week"   -> Period.WEEK
    "year"   -> Period.YEAR
    "decade" -> Period.DECADE
    else     -> throw IllegalArgumentException("invalid period")
}

val Period.value: String
    get() = when (this) {
        Period.WEEK   -> "week"
        Period.YEAR   -> "year"
        Period.DECADE -> "decade"
    }

fun Period.toSubPeriodRangeSec(startedAtSec: Long) = LongRange(
    startedAtSec, when (this) {
        Period.WEEK   -> DateTimeUtil.getEndOfDateMillis(startedAtSec * 1000)
        Period.YEAR   -> DateTimeUtil.getEndOfMonthMillis(startedAtSec * 1000)
        Period.DECADE -> DateTimeUtil.getEndOfYearMillis(startedAtSec * 1000)
    } / 1000
)

fun Period.toPeriodRangeSec(startedAtSec: Long) = when (this) {
    Period.WEEK   -> DateTimeUtil.getStartOfDatesMillisInWeek(startedAtSec * 1000)
    Period.YEAR   -> DateTimeUtil.getStartOfDatesMillisInYear(startedAtSec * 1000)
    Period.DECADE -> DateTimeUtil.getStartOfDatesMillisInDecade(startedAtSec * 1000)
}.map { it / 1000 }