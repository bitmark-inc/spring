/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.model.entity.*


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

        fun newInstance(post: PostR): PostModelView {
            val tags = post.tags ?: listOf()
            val location = post.location?.name
            val content = post.content ?: ""
            val title = post.title ?: ""
            val url = when (post.type) {
                PostType.PHOTO, PostType.STORY, PostType.VIDEO -> BuildConfig.FBM_ASSET_ENDPOINT + "/${post.mediaName
                    ?: ""}"
                PostType.LINK                                  -> post.url
                else                                           -> null
            }
            val thumbnail = if (post.type == PostType.VIDEO) {
                BuildConfig.FBM_ASSET_ENDPOINT + "/${post.mediaName ?: ""}"
            } else ""
            return PostModelView(
                post.type,
                content,
                url,
                tags,
                location,
                post.timestamp,
                title,
                thumbnail
            )
        }
    }

    fun hasSingleTag() = tags.size == 1

    fun hasLocation() = location != null
}