/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import androidx.room.Embedded
import androidx.room.Relation
import com.bitmark.fbm.data.model.entity.*


class PostData(
    @Embedded
    private val post: PostR,

    @Relation(entity = CommentR::class, entityColumn = "post_id", parentColumn = "timestamp")
    private val comments: List<CommentR> = listOf(),

    @Relation(
        entity = LocationR::class,
        entityColumn = "id",
        parentColumn = "location_id"
    )
    private val locations: List<LocationR> = listOf()
) : Data {

    val type: PostType
        get() = post.type

    val content: String?
        get() = post.content

    val url: String?
        get() = post.url

    val tags: List<String>?
        get() = post.tags?.map { t -> t.name }

    val timestampSec: Long
        get() = post.timestampSec

    val title: String?
        get() = post.title

    val thumbnail: String?
        get() = post.mediaData?.first()?.thumbnail

    val source: String?
        get() = post.mediaData?.first()?.canonicalSource

    val location: LocationR?
        get() = if (locations.isEmpty()) null else locations[0]

    val timestamp: Long
        get() = post.timestamp

    val mediaType: MediaType?
        get() = post.mediaType

    val mediaData: List<MediaData>?
        get() = post.mediaData
}

fun PostData.hasVideo() =
    mediaData != null && mediaData!!.firstOrNull { d -> d.type == MediaType.VIDEO.string() } != null