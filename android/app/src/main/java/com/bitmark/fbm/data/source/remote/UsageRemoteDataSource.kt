/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.model.entity.PostR
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.applyRequiredValues
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import com.google.gson.Gson
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class UsageRemoteDataSource @Inject constructor(
    private val context: Context, // TODO remove later
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun listPostByType(type: PostType, fromSec: Long, toSec: Long) =
        listPosts().map { posts -> posts.filter { p -> p.timestampSec in fromSec..toSec && p.type == type } }

    fun listPostByTag(tag: String, fromSec: Long, toSec: Long) = listPosts().map { posts ->
        posts.filter { p ->
            p.timestampSec in fromSec..toSec && p.tags?.contains(tag) == true
        }
    }

    fun listPostByLocation(location: String, fromSec: Long, toSec: Long) = listPosts().map { posts ->
        posts.filter { p ->
            p.timestampSec in fromSec..toSec && p.location?.name == location
        }
    }

    private fun listPosts() = Single.fromCallable {
        val json = context.assets.open("posts.json").bufferedReader()
            .use { r -> r.readText() }
        val gson = Gson().newBuilder().create()
        val posts = gson.fromJson(json, List::class.java).map { p ->
            gson.fromJson(gson.toJson(p), PostR::class.java)
        }.filter { p -> p.type != PostType.UNSPECIFIED }
        posts.applyRequiredValues()
        posts
    }.subscribeOn(Schedulers.io())
}