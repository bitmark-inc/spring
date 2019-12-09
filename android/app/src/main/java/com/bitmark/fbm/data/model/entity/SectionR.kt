/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import com.google.gson.Gson
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class SectionR(
    @Expose
    @SerializedName("section_name")
    val name: SectionName,

    @Expose
    @SerializedName("period")
    val period: Period,

    @Expose
    @SerializedName("period_started_at")
    val periodStartedAt: Long,

    @Expose
    @SerializedName("diff_from_previous")
    val diffFromPrev: Int,

    @Expose
    @SerializedName("quantity")
    val quantity: Int,

    @Expose
    @SerializedName("groups")
    val groups: Map<String, Any>
) : Record

inline fun <reified T> SectionR.getGroup(key: String): T {
    val gson = Gson().newBuilder().create()
    val group = groups[key] ?: error("$key is not existing")
    val json = gson.toJson(group)
    return gson.fromJson(json, T::class.java)
}

inline fun <reified T> SectionR.getArrayGroup(key: String): List<T> {
    val gson = Gson().newBuilder().create()
    val group = groups[key] ?: error("$key is not existing")
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
    LOCATION
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