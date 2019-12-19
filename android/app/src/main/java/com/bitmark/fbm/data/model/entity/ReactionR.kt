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
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Reaction",
    indices = [Index(
        value = ["id"],
        unique = true
    ), Index(value = ["timestamp"]),
        Index(value = ["reaction"])]
)
data class ReactionR(
    @PrimaryKey(autoGenerate = true)
    @Expose
    @SerializedName("id")
    @ColumnInfo(name = "id")
    val id: Long,

    @Expose
    @SerializedName("actor")
    @ColumnInfo(name = "actor")
    val actor: String,

    @Expose
    @SerializedName("reaction")
    @ColumnInfo(name = "reaction")
    val reaction: Reaction,

    @Expose
    @SerializedName("timestamp")
    @ColumnInfo(name = "timestamp")
    val timestampSec: Long,

    @Expose
    @SerializedName("title")
    @ColumnInfo(name = "title")
    val title: String
) : Record

val ReactionR.timestamp: Long
    get() = timestampSec * 1000

enum class Reaction {
    @Expose
    @SerializedName("LIKE")
    LIKE,

    @Expose
    @SerializedName("LOVE")
    LOVE,

    @Expose
    @SerializedName("HAHA")
    HAHA,

    @Expose
    @SerializedName("WOW")
    WOW,

    @Expose
    @SerializedName("SAD")
    SAD,

    @Expose
    @SerializedName("ANGRY")
    ANGRY;

    companion object
}

val Reaction.value: String
    get() = when (this) {
        Reaction.LIKE  -> "LIKE"
        Reaction.LOVE  -> "LOVE"
        Reaction.HAHA  -> "HAHA"
        Reaction.WOW   -> "WOW"
        Reaction.SAD   -> "SAD"
        Reaction.ANGRY -> "ANGRY"
    }

fun Reaction.Companion.fromString(reaction: String) = when (reaction) {
    "LIKE"  -> Reaction.LIKE
    "LOVE"  -> Reaction.LOVE
    "HAHA"  -> Reaction.HAHA
    "WOW"   -> Reaction.WOW
    "SAD"   -> Reaction.SAD
    "ANGRY" -> Reaction.ANGRY
    else    -> error("invalid reaction string: $reaction")
}