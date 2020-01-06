/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.MediaData
import com.bitmark.fbm.data.model.entity.MediaType
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.fromString


data class PostModelView(
    val type: PostType,

    val content: String,

    val url: String?,

    val uri: String?,

    val tags: List<String>,

    val location: String?,

    val timestamp: Long,

    val title: String,

    val thumbnail: String?,

    val mediaData: List<MediaData>?

) : ModelView {

    companion object {

        fun newInstance(post: PostData): PostModelView {
            val tags = post.tags ?: listOf()
            val location = post.location?.name
            val content = post.content ?: ""
            val title = post.title ?: ""
            val uri = post.source
            val url = when (post.type) {
                PostType.MEDIA -> post.source
                PostType.LINK  -> post.url
                else           -> null
            }
            return PostModelView(
                post.type,
                content,
                url,
                uri,
                tags,
                location,
                post.timestamp,
                title,
                post.thumbnail,
                post.mediaData
            )
        }

    }

}

fun PostModelView.hasLocation() = location != null

fun PostModelView.isMultiMediaPost() = mediaData != null && mediaData.size > 1

val PostModelView.mediaType: MediaType?
    get() = if (mediaData == null) null else MediaType.fromString(mediaData[0].type)