/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.*
import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.model.FriendData
import com.bitmark.fbm.util.ext.removeQuote
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName
import java.net.URLEncoder

@Entity(
    tableName = "Post",
    indices = [Index(
        value = ["timestamp"],
        unique = true
    ), Index(value = ["type"]), Index(value = ["location_id"])],
    foreignKeys = [ForeignKey(
        entity = LocationR::class,
        parentColumns = ["id"],
        childColumns = ["location_id"],
        onDelete = ForeignKey.CASCADE,
        onUpdate = ForeignKey.CASCADE
    )]
)
data class PostR(

    @Expose
    @SerializedName("post")
    @ColumnInfo(name = "content")
    val content: String?,

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
    @ColumnInfo(name = "type")
    var type: PostType,

    @Expose
    @SerializedName("location_id")
    @ColumnInfo(name = "location_id")
    var locationId: String?,

    @Expose
    @SerializedName("tags")
    @ColumnInfo(name = "tags")
    val tags: List<FriendData>?,

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

val PostR.mediaType: MediaType?
    get() = if (mediaData?.get(0) == null) null else MediaType.fromString(mediaData[0].type)

data class MediaData(
    @Expose
    @SerializedName("source")
    var source: String,

    @Expose
    @SerializedName("thumbnail")
    val thumbnail: String?,

    @Expose
    @SerializedName("type")
    val type: String
)

val MediaData.canonicalSource: String
    get() = if (type == MediaType.PHOTO.string()) {
        BuildConfig.FBM_ASSET_ENDPOINT + "?key=${URLEncoder.encode(source, "UTF-8") ?: ""}"
    } else {
        source
    }

enum class MediaType {
    PHOTO,
    VIDEO;

    companion object
}

fun MediaType.string() = when (this) {
    MediaType.PHOTO -> "photo"
    MediaType.VIDEO -> "video"
}

fun MediaType.Companion.fromString(type: String) = when (type) {
    "photo" -> MediaType.PHOTO
    "video" -> MediaType.VIDEO
    else    -> error("unsupported media type $type")
}

fun List<PostR>.applyRequiredValues() {
    for (post in this) {
        post.applyLocation()
    }
}

fun List<PostR>.canonical() {
    for (post in this) {
        post.tags?.forEach { t -> t.name.removeQuote() }
    }
}

internal fun PostR.applyLocation() {
    locationId = location?.id
}

val PostR.timestamp: Long
    get() = timestampSec * 1000

enum class PostType {
    @Expose
    @SerializedName("update")
    UPDATE,

    @Expose
    @SerializedName("media")
    MEDIA,

    @Expose
    @SerializedName("story")
    STORY,

    @Expose
    @SerializedName("link")
    LINK,

    @Expose
    @SerializedName("unspecified")
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