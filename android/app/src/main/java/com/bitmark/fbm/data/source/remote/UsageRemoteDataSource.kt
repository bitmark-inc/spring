/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.applyRequiredValues
import com.bitmark.fbm.data.model.entity.canonical
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import javax.inject.Inject


class UsageRemoteDataSource @Inject constructor(
    private val context: Context, // TODO remove later
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun listPost(startedAtSec: Long, endedAtSec: Long) = listRemotePost(startedAtSec, endedAtSec)

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long) = listRemotePost(
        startedAtSec,
        endedAtSec
    ).map { posts ->
        posts.canonical()
        posts.applyRequiredValues()
        posts.filter { p -> p.type == type }
    }

    fun listPostByTag(tag: String, startedAtSec: Long, endedAtSec: Long) = listRemotePost(
        startedAtSec,
        endedAtSec
    ).map { posts -> posts.filter { p -> p.tags?.map { t -> t.name }?.contains(tag) == true } }

    fun listPostByLocations(
        locations: List<String>,
        startedAtSec: Long,
        endedAtSec: Long
    ) = listRemotePost(
        startedAtSec,
        endedAtSec
    ).map { posts -> posts.filter { p -> p.location != null && locations.contains(p.location!!.name) } }

    private fun listRemotePost(startedAtSec: Long, endedAtSec: Long) =
        fbmApi.listPost(startedAtSec, endedAtSec).map { res -> res["result"] }

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long
    ) = listReaction(
        startedAtSec,
        endedAtSec
    ).map { reactions -> reactions.filter { r -> r.reaction == reaction } }

    fun listReaction(startedAtSec: Long, endedAtSec: Long) =
        fbmApi.listReaction(startedAtSec, endedAtSec).map { res -> res["result"] }
}