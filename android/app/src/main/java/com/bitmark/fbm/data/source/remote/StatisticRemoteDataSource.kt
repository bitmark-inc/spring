/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.value
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class StatisticRemoteDataSource @Inject constructor(
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun listUsageStatistic(period: Period, periodStartedAtSec: Long) =
        fbmApi.listUsage(period.value, periodStartedAtSec).map { res -> res["result"] }.subscribeOn(
            Schedulers.io()
        )

    fun getInsightData() =
        fbmApi.getInsight().map { res -> res["result"] }.subscribeOn(Schedulers.io())
}