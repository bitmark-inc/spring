/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.applyRequiredValues
import com.bitmark.fbm.data.model.entity.canonical
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class UsageRemoteDataSource @Inject constructor(
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

    fun listPostByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long
    ) = listRemotePost(
        startedAtSec,
        endedAtSec
    ).map { posts -> posts.filter { p -> p.location != null && locationNames.contains(p.location!!.name) } }

    private fun listRemotePost(startedAtSec: Long, endedAtSec: Long) =
        fbmApi.listPost(startedAtSec, endedAtSec).map { res -> res["result"] }.subscribeOn(
            Schedulers.io()
        )

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long
    ) = listReaction(
        startedAtSec,
        endedAtSec
    ).map { reactions -> reactions.filter { r -> r.reaction == reaction } }

    fun listReaction(startedAtSec: Long, endedAtSec: Long) =
        fbmApi.listReaction(startedAtSec, endedAtSec).map { res -> res["result"] }.subscribeOn(
            Schedulers.io()
        )

    fun getPresignedUrl(uri: String) =
        fbmApi.getPresignedUrl(uri).map { res ->
            Pair(
                uri,
                res.headers()["Location"] ?: error("Could not get presigned URL")
            )
        }.subscribeOn(Schedulers.io())
}