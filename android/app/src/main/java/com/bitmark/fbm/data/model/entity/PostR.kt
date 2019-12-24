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
    tableName = "Post",
    indices = [Index(
        value = ["timestamp"],
        unique = true
    ), Index(value = ["type"])]
)
data class PostR(

    @Expose
    @SerializedName("post")
    @ColumnInfo(name = "content")
    val content: String?,

    @Expose
    @SerializedName("tags")
    @ColumnInfo(name = "tags")
    val tags: List<String>?,

    @Expose
    @SerializedName("timestamp")
    @ColumnInfo(name = "timestamp")
    @PrimaryKey
    val timestampSec: Long,

    @Expose
    @SerializedName("title")
    @ColumnInfo(name = "title")
    val title: String?,

    @Expose
    @SerializedName("type")
    @ColumnInfo(name = "raw_type")
    val rawType: String?,

    @Expose
    @SerializedName("post_type")
    @ColumnInfo(name = "type")
    var type: PostType,

    @Expose
    @SerializedName("location_name")
    @ColumnInfo(name = "location_name")
    var locationName: String?,

    @Expose
    @SerializedName("mediaData")
    @ColumnInfo(name = "media_data")
    val mediaData: List<MediaData>?,

    @Expose
    @SerializedName("url")
    @ColumnInfo(name = "url")
    val url: String?
) : Record {

    @Expose
    @SerializedName("location")
    @Ignore
    var location: LocationR? = null

    @Expose
    @SerializedName("comment")
    @Ignore
    var comments: List<CommentR>? = null
}

data class MediaData(
    @Expose
    @SerializedName("source")
    val source: String,

    @Expose
    @SerializedName("thumbnail")
    val thumbnail: String?,

    @Expose
    @SerializedName("type")
    val type: String
)

fun List<PostR>.applyRequiredValues() {
    for (post in this) {
        post.applyPostType()
        post.applyLocation()
    }
}

fun List<PostR>.canonical() {
    for (post in this) {
        post.tags?.forEach { t -> t.replace("'", "") }
    }
}

internal fun PostR.applyPostType() {
    type = when (rawType) {
        "update" -> PostType.UPDATE
        "media"  -> PostType.MEDIA
        "story"  -> PostType.STORY
        "link"   -> PostType.LINK
        else     -> PostType.UNSPECIFIED
    }
}

internal fun PostR.applyLocation() {
    locationName = location?.name
}

val PostR.timestamp: Long
    get() = timestampSec * 1000

enum class PostType {
    UPDATE,
    MEDIA,
    STORY,
    LINK,
    UNSPECIFIED;

    companion object
}

fun PostType.Companion.indexOf(type: String) = PostType.fromString(type).ordinal

fun PostType.Companion.fromIndex(index: Int) = PostType.values()[index]

fun PostType.Companion.fromString(type: String) = when (type) {
    "update"      -> PostType.UPDATE
    "media"       -> PostType.MEDIA
    "story"       -> PostType.STORY
    "link"        -> PostType.LINK
    "unspecified" -> PostType.UNSPECIFIED
    else          -> error("invalid type: $type")
}

val PostType.value: String
    get() = when (this) {
        PostType.UPDATE      -> "update"
        PostType.MEDIA       -> "media"
        PostType.STORY       -> "story"
        PostType.LINK        -> "link"
        PostType.UNSPECIFIED -> "unspecified"
    }