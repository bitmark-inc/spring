/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.response.GetStatisticResponse
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import com.google.gson.Gson
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class UsageRemoteDataSource @Inject constructor(
    private val context: Context, // TODO remove later
    private val gson: Gson, // TODO remove later
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun getStatistic(period: Period) = Single.fromCallable {
        val json = context.assets?.open(
            when (period) {
                Period.WEEK   -> "usage_week.json"
                Period.YEAR   -> "usage_year.json"
                Period.DECADE -> "usage_decade.json"
            }
        )?.bufferedReader().use { r -> r?.readText() }
        gson.fromJson(json, GetStatisticResponse::class.java).sectionRs
    }.subscribeOn(Schedulers.io())

    fun listPostByType(type: PostType, from: Long, to: Long) =
        listPosts().map { posts -> posts.filter { p -> p.timestamp in from..to && p.type == type } }

    fun listPostByTag(tag: String, from: Long, to: Long) = listPosts().map { posts ->
        posts.filter { p ->
            p.timestamp in from..to && p.tags?.contains(tag) == true
        }
    }

    fun listPostByLocation(location: String, from: Long, to: Long) = listPosts().map { posts ->
        posts.filter { p ->
            p.timestamp in from..to && p.location?.name == location
        }
    }

    private fun listPosts() = Single.fromCallable {
        val json = context.assets.open("posts.json").bufferedReader()
            .use { r -> r.readText() }
        val gson = Gson().newBuilder().create()
        gson.fromJson(json, List::class.java).map { p ->
            gson.fromJson(gson.toJson(p), PostR::class.java)
        }.filter { p -> p.type != PostType.UNSPECIFIED }
    }.subscribeOn(Schedulers.io())
}