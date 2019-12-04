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
    val name: String,

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
) : Record {

    inline fun <reified T> getGroup(key: String): T {
        val gson = Gson().newBuilder().create()
        val group = groups[key] ?: error("$key is not existing")
        val json = gson.toJson(group)
        return gson.fromJson(json, T::class.java)
    }

    inline fun <reified T> getArrayGroup(key: String): List<T> {
        val gson = Gson().newBuilder().create()
        val group = groups[key] ?: error("$key is not existing")
        if (group !is List<*>) error("not a list")
        val result = mutableListOf<T>()
        group.forEach { g ->
            result.add(gson.fromJson(gson.toJson(g), T::class.java))
        }
        return result
    }

}

data class GroupEntity(
    @Expose
    @SerializedName("name")
    val name: String,

    @Expose
    @SerializedName("data")
    val data: Map<String, Int>
) : Record

enum class Period(val value: String) {
    @Expose
    @SerializedName("week")
    WEEK("week"),

    @Expose
    @SerializedName("year")
    YEAR("year"),

    @Expose
    @SerializedName("decade")
    DECADE("decade");

    companion object {
        fun fromString(period: String) = when (period) {
            "week"   -> WEEK
            "year"   -> YEAR
            "decade" -> DECADE
            else     -> throw IllegalArgumentException("invalid period")
        }
    }
}