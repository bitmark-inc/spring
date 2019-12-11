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
    @SerializedName("url")
    @ColumnInfo(name = "url")
    val url: String?,

    @Expose
    @SerializedName("photo")
    @ColumnInfo(name = "photo")
    val mediaDir: String?,

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
    @SerializedName("thumbnail")
    @ColumnInfo(name = "thumbnail")
    val thumbnail: String?,

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
    var locationName: String?
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

fun List<PostR>.applyRequiredValues() {
    for (post in this) {
        post.applyPostType()
        post.applyLocation()
    }
}

internal fun PostR.applyPostType() {
    type = when {
        rawType == null && content != null -> PostType.UPDATE
        rawType == "photo"                 -> PostType.PHOTO
        rawType == "video"                 -> PostType.VIDEO
        rawType == "story"                 -> PostType.STORY
        rawType == "external"              -> PostType.LINK
        else                               -> PostType.UNSPECIFIED
    }
}

internal fun PostR.applyLocation() {
    locationName = location?.name
}

val PostR.timestamp: Long
    get() = timestampSec * 1000

val PostR.mediaName: String?
    get() = mediaDir?.replace("photos_and_videos/", "")

enum class PostType {
    UPDATE,
    PHOTO,
    VIDEO,
    STORY,
    LINK,
    UNSPECIFIED;

    companion object
}

fun PostType.Companion.fromString(type: String) = when (type) {
    "update"      -> PostType.UPDATE
    "photo"       -> PostType.PHOTO
    "video"       -> PostType.VIDEO
    "story"       -> PostType.STORY
    "link"        -> PostType.LINK
    "unspecified" -> PostType.UNSPECIFIED
    else          -> error("invalid type: $type")
}

val PostType.value: String
    get() = when (this) {
        PostType.UPDATE      -> "update"
        PostType.PHOTO       -> "photo"
        PostType.VIDEO       -> "video"
        PostType.STORY       -> "story"
        PostType.LINK        -> "link"
        PostType.UNSPECIFIED -> "unspecified"
    }