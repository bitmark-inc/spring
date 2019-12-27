/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.MediaType
import com.bitmark.fbm.data.model.entity.PostType
import java.net.URLEncoder


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

    val mediaType: MediaType?

) : ModelView {

    companion object {

        fun newInstance(post: PostData): PostModelView {
            val tags = post.tags ?: listOf()
            val location = post.location?.name
            val content = post.content ?: ""
            val title = post.title ?: ""
            val uri = when (post.type) {
                PostType.MEDIA, PostType.STORY -> {
                    if (post.mediaType == MediaType.PHOTO) post.source else post.thumbnail
                }
                else                           -> null
            }
            val url = when (post.type) {
                PostType.MEDIA, PostType.STORY -> {
                    if (post.mediaType == MediaType.VIDEO) {
                        post.source
                    } else {
                        BuildConfig.FBM_ASSET_ENDPOINT + "?key=${URLEncoder.encode(uri, "UTF-8")
                            ?: ""}"
                    }

                }
                PostType.LINK                  -> post.url
                else                           -> null
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
                post.mediaType
            )
        }
    }

    fun hasSingleTag() = tags.size == 1

    fun hasLocation() = location != null
}