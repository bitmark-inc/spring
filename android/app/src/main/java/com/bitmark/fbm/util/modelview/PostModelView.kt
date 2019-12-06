/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.PostR
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

        fun newInstance(post: PostR): PostModelView {
            val tags = post.tags ?: listOf()
            val location = post.location?.name
            val content = post.content ?: ""
            val title = post.title ?: ""
            val url = when (post.getType()) {
                PostType.PHOTO, PostType.STORY, PostType.VIDEO -> "https://bitmark-mobile-files.s3-ap-northeast-1.amazonaws.com/fb_data/%s".format(
                    post.mediaName?.replace("photos_and_videos/", "") ?: ""
                )
                PostType.LINK                                  -> post.url
                else                                           -> null
            }
            val thumbnail = if (post.getType() == PostType.VIDEO) {
                "https://bitmark-mobile-files.s3-ap-northeast-1.amazonaws.com/fb_data/%s".format(
                    post.mediaName?.replace("photos_and_videos/", "") ?: ""
                )
            } else ""
            return PostModelView(
                post.getType(),
                content,
                url,
                tags,
                location,
                post.getTimestamp(),
                title,
                thumbnail
            )
        }
    }

    fun hasSingleTag() = tags.size == 1

    fun hasMultiTags() = tags.size > 1

    fun hasEmptyTags() = tags.isEmpty()

    fun hasLocation() = location != null
}