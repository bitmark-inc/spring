/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class PostR(

    @Expose
    @SerializedName("id")
    val id: String,

    @Expose
    @SerializedName("type")
    val rawType: String?,

    @Expose
    @SerializedName("post")
    val content: String?,

    @Expose
    @SerializedName("url")
    val url: String,

    @Expose
    @SerializedName("photo")
    val mediaDir: String?,

    @Expose
    @SerializedName("tags")
    val tags: List<String>?,

    @Expose
    @SerializedName("location")
    val location: LocationR?,

    @Expose
    @SerializedName("timestamp")
    val timestampSec: Long,

    @Expose
    @SerializedName("title")
    val title: String?,

    @Expose
    @SerializedName("comment")
    val comment: CommentR,

    @Expose
    @SerializedName("thumbnail")
    val thumbnail: String?
) : Record

val PostR.type: PostType
    get() = when {
        rawType == null && content != null -> PostType.UPDATE
        rawType == "photo"                 -> PostType.PHOTO
        rawType == "video"                 -> PostType.VIDEO
        rawType == "story"                 -> PostType.STORY
        rawType == "external"              -> PostType.LINK
        else                               -> PostType.UNSPECIFIED
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
    UNSPECIFIED
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