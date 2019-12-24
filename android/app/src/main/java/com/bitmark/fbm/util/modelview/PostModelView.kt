/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostType


data class PostModelView(
    val type: PostType,

    val content: String,

    val url: String?,

    val tags: List<String>,

    val location: String?,

    val timestamp: Long,

    val title: String,

    val thumbnail: String?

) : ModelView {

    companion object {

        fun newInstance(post: PostData): PostModelView {
            val tags = post.tags ?: listOf()
            val location = post.location?.name
            val content = post.content ?: ""
            val title = post.title ?: ""
            val url = when (post.type) {
                PostType.MEDIA, PostType.STORY -> {
                    val source = if (post.mediaType == "photo") post.source else post.thumbnail
                    BuildConfig.FBM_ASSET_ENDPOINT + "/${source ?: ""}"
                }
                PostType.LINK                  -> post.url
                else                           -> null
            }
            return PostModelView(
                post.type,
                content,
                url,
                tags,
                location,
                post.timestamp,
                title,
                post.thumbnail
            )
        }
    }

    fun hasSingleTag() = tags.size == 1

    fun hasLocation() = location != null
}