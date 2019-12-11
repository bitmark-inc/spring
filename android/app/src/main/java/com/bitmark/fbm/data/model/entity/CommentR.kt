/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.*
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Comment",
    indices = [Index(
        value = ["id"],
        unique = true
    ), Index(value = ["timestamp"]), Index(value = ["post_id"])],
    foreignKeys = [ForeignKey(
        entity = PostR::class,
        parentColumns = ["timestamp"],
        childColumns = ["post_id"],
        onDelete = ForeignKey.CASCADE,
        onUpdate = ForeignKey.CASCADE
    )]
)
data class CommentR(

    @Expose
    @SerializedName("id")
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long,

    @Expose
    @SerializedName("post_id")
    @ColumnInfo(name = "post_id")
    var postId: Long,

    @Expose
    @SerializedName("timestamp")
    @ColumnInfo(name = "timestamp")
    val timestamp: Long,

    @Expose
    @SerializedName("comment")
    @ColumnInfo(name = "content")
    val content: String,

    @Expose
    @SerializedName("author")
    @ColumnInfo(name = "author")
    val author: String
) : Record

fun List<CommentR>.applyPostId(id: Long) {
    for (comment in this) {
        comment.postId = id
    }
}