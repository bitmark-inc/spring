/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Criteria",
    indices = [Index(value = ["query"], unique = true)]
)
data class CriteriaR(
    @Expose
    @SerializedName("type")
    @ColumnInfo(name = "type")
    val type: CriteriaType,

    @Expose
    @SerializedName("started_at")
    @ColumnInfo(name = "started_at")
    val startedAt: Long,

    @Expose
    @SerializedName("ended_at")
    @ColumnInfo(name = "ended_at")
    val endedAt: Long,

    @Expose
    @SerializedName("query")
    @ColumnInfo(name = "query")
    @PrimaryKey
    val query: String
) : Record {
    companion object
}

enum class CriteriaType {
    STATISTIC,
    POST,
    REACTION;

    companion object
}

fun CriteriaType.Companion.fromString(type: String) = when (type) {
    "statistic" -> CriteriaType.STATISTIC
    "post"      -> CriteriaType.POST
    "reaction"  -> CriteriaType.REACTION
    else        -> error("unsupported type: $type")
}

val CriteriaType.value: String
    get() = when (this) {
        CriteriaType.POST      -> "post"
        CriteriaType.REACTION  -> "reaction"
        CriteriaType.STATISTIC -> "statistic"
    }

fun CriteriaR.Companion.fromStatisticWType(type: String, startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.STATISTIC,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.STATISTIC.value}?started_at=$startedAt&ended_at=$endedAt&type=$type"
    )

fun CriteriaR.Companion.fromPostWRange(startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.POST,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.POST.value}?started_at=$startedAt&ended_at=$endedAt"
    )

fun CriteriaR.Companion.fromPostWType(type: PostType, startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.POST,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.POST.value}?started_at=$startedAt&ended_at=$endedAt&type=$type"
    )

fun CriteriaR.Companion.fromPostWTags(tags: List<String>, startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.POST,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.POST.value}?started_at=$startedAt&ended_at=$endedAt&tags=[${tags.joinToString(
            ","
        )}]"
    )

fun CriteriaR.Companion.fromPostWLocations(places: List<String>, startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.POST,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.POST.value}?started_at=$startedAt&ended_at=$endedAt&places=[${places.joinToString(
            ","
        )}]"
    )

fun CriteriaR.Companion.fromReactionWRange(startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.REACTION,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.REACTION.value}?started_at=$startedAt&ended_at=$endedAt"
    )

fun CriteriaR.Companion.fromReactionWType(type: Reaction, startedAt: Long, endedAt: Long) =
    CriteriaR(
        type = CriteriaType.REACTION,
        startedAt = startedAt,
        endedAt = endedAt,
        query = "${CriteriaType.REACTION.value}?started_at=$startedAt&ended_at=$endedAt&type=${type.value}"
    )
