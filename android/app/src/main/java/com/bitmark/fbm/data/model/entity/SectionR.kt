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
    val periodStartedAt: Long,

    @Expose
    @SerializedName("diff_from_previous")
    @ColumnInfo(name = "diff_from_previous")
    val diffFromPrev: Int,

    @Expose
    @SerializedName("quantity")
    @ColumnInfo(name = "quantity")
    val quantity: Int,

    @Expose
    @SerializedName("groups")
    @ColumnInfo(name = "groups")
    val groups: Map<String, Any>
) : Record

inline fun <reified T> SectionR.getGroup(g: GroupName): T {
    val gson = Gson().newBuilder().create()
    val group = groups[g.value] ?: error("${g.value} is not existing")
    val json = gson.toJson(group)
    return gson.fromJson(json, T::class.java)
}

inline fun <reified T> SectionR.getArrayGroup(g: GroupName): List<T> {
    val gson = Gson().newBuilder().create()
    val group = groups[g.value] ?: error("${g.value} is not existing")
    if (group !is List<*>) error("not a list")
    val result = mutableListOf<T>()
    group.forEach { g ->
        result.add(gson.fromJson(gson.toJson(g), T::class.java))
    }
    return result
}

enum class SectionName {
    @Expose
    @SerializedName("posts")
    POST,

    @Expose
    @SerializedName("reactions")
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
    LOCATION;

    companion object
}

fun SectionName.Companion.fromString(name: String) = when (name) {
    "posts"        -> SectionName.POST
    "reactions"    -> SectionName.REACTION
    "messages"     -> SectionName.MESSAGE
    "ad_interests" -> SectionName.AD_INTEREST
    "advertisers"  -> SectionName.ADVERTISER
    "locations"    -> SectionName.LOCATION
    else           -> error("invalid name")
}

val SectionName.value: String
    get() = when (this) {
        SectionName.POST        -> "posts"
        SectionName.REACTION    -> "reactions"
        SectionName.MESSAGE     -> "messages"
        SectionName.AD_INTEREST -> "ad_interests"
        SectionName.ADVERTISER  -> "advertisers"
        SectionName.LOCATION    -> "locations"
    }

data class GroupEntity(
    @Expose
    @SerializedName("name")
    val name: String,

    @Expose
    @SerializedName("data")
    val data: Map<String, Int>
) : Record

enum class GroupName {
    TYPE,
    DAY,
    FRIEND,
    PLACE,
    AREA;

    companion object
}

val GroupName.value: String
    get() = when (this) {
        GroupName.TYPE   -> "type"
        GroupName.DAY    -> "day"
        GroupName.FRIEND -> "friend"
        GroupName.PLACE  -> "place"
        GroupName.AREA   -> "area"
    }

fun GroupName.Companion.fromString(name: String) = when (name) {
    "type"   -> GroupName.TYPE
    "day"    -> GroupName.DAY
    "friend" -> GroupName.FRIEND
    "place"  -> GroupName.PLACE
    "area"   -> GroupName.AREA
    else     -> error("invalid group name")
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