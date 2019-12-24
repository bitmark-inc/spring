/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
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

    fun listPostByTags(tags: List<String>, startedAtSec: Long, endedAtSec: Long) = listRemotePost(
        startedAtSec,
        endedAtSec
    ).map { posts -> posts.filter { p -> p.tags?.any(tags::contains) == true } }

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

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        listReaction().map { reactions ->
            reactions.filter { r -> r.timestampSec in startedAtSec..endedAtSec }.take(limit)
        }

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) =
        listReaction().map { reactions ->
            reactions.filter { r -> r.timestampSec in startedAtSec..endedAtSec && r.reaction == reaction }
                .take(limit)
        }

    private fun listReaction() = Single.fromCallable {
        val json = context.assets.open("reactions.json").bufferedReader()
            .use { r -> r.readText() }
        val gson = newGsonInstance()
        gson.fromJson(json, List::class.java).map { p ->
            gson.fromJson(gson.toJson(p), ReactionR::class.java)
        }
    }.subscribeOn(Schedulers.io())
}