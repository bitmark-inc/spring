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
    private val type: String?,

    @Expose
    @SerializedName("post")
    val content: String?,

    @Expose
    @SerializedName("url")
    val url: String,

    @Expose
    @SerializedName("photo")
    val mediaName: String?,

    @Expose
    @SerializedName("tags")
    val tags: List<String>?,

    @Expose
    @SerializedName("location")
    val location: LocationR?,

    @Expose
    @SerializedName("timestamp")
    private val timestamp: Long,

    @Expose
    @SerializedName("title")
    val title: String?,

    @Expose
    @SerializedName("comment")
    val comment: CommentR,

    @Expose
    @SerializedName("thumbnail")
    val thumbnail: String?
) : Record {

    fun getType() = when {
        type == null && content != null -> PostType.UPDATE
        type == "photo"                 -> PostType.PHOTO
        type == "video"                 -> PostType.VIDEO
        type == "story"                 -> PostType.STORY
        type == "external"              -> PostType.LINK
        else                            -> PostType.UNSPECIFIED
    }

    fun getTimestamp() = timestamp * 1000

}

enum class PostType(val value: String) {
    UPDATE("update"),
    PHOTO("photo"),
    VIDEO("video"),
    STORY("story"),
    LINK("link"),
    UNSPECIFIED("unspecified");

    companion object {
        fun fromString(type: String) = when (type) {
            "update" -> UPDATE
            "photo"  -> PHOTO
            "video"  -> VIDEO
            "story"  -> STORY
            "link"   -> LINK
            else     -> UNSPECIFIED
        }
    }
}