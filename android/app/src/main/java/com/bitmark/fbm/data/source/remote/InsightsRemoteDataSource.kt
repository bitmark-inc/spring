/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.entity.LocationR
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class InsightsRemoteDataSource @Inject constructor(
    private val context: Context, // TODO remove later
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun listLocation(startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        listLocation().map { locations ->
            locations.filter { l -> l.createdAtSec in startedAtSec..endedAtSec }.take(limit)
        }

    fun listLocationByNames(
        names: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) =
        listLocation().map { locations ->
            locations.filter { l -> l.name in names && l.createdAtSec in startedAtSec..endedAtSec }
                .take(limit)
        }

    private fun listLocation() = Single.fromCallable {
        val json = context.assets.open("locations.json").bufferedReader()
            .use { r -> r.readText() }
        val gson = newGsonInstance()
        gson.fromJson(json, List::class.java).map { p ->
            gson.fromJson(gson.toJson(p), LocationR::class.java)
        }
    }.subscribeOn(Schedulers.io())

}