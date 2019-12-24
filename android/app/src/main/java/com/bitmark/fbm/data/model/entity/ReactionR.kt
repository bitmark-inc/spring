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
    @SerializedName("like")
    LIKE,

    @Expose
    @SerializedName("love")
    LOVE,

    @Expose
    @SerializedName("haha")
    HAHA,

    @Expose
    @SerializedName("wow")
    WOW,

    @Expose
    @SerializedName("sorry")
    SAD,

    @Expose
    @SerializedName("anger")
    ANGRY;

    companion object
}

fun Reaction.Companion.indexOf(reaction: String) = Reaction.fromString(reaction).ordinal

fun Reaction.Companion.fromIndex(index: Int) = Reaction.values()[index]

val Reaction.value: String
    get() = when (this) {
        Reaction.LIKE  -> "like"
        Reaction.LOVE  -> "love"
        Reaction.HAHA  -> "haha"
        Reaction.WOW   -> "wow"
        Reaction.SAD   -> "sorry"
        Reaction.ANGRY -> "anger"
    }

fun Reaction.Companion.fromString(reaction: String) = when (reaction) {
    "like"  -> Reaction.LIKE
    "love"  -> Reaction.LOVE
    "haha"  -> Reaction.HAHA
    "wow"   -> Reaction.WOW
    "sorry"   -> Reaction.SAD
    "anger" -> Reaction.ANGRY
    else    -> error("invalid reaction string: $reaction")
}