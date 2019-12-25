/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import android.content.Context
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.value
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class StatisticRemoteDataSource @Inject constructor(
    private val context: Context, // TODO remove later
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun listUsage(period: Period, periodStartedAtSec: Long) =
        fbmApi.listUsage(period.value, periodStartedAtSec).map { res -> res["result"] }.subscribeOn(
            Schedulers.io()
        )

    fun listInsights(period: Period, periodStartedAtSec: Long) =
        fbmApi.listInsight(
            period.value,
            periodStartedAtSec
        ).map { res -> res["result"] }.subscribeOn(Schedulers.io())
}