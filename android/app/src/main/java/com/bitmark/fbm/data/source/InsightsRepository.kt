/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.source.local.InsightsLocalDataSource
import com.bitmark.fbm.data.source.remote.InsightsRemoteDataSource


class InsightsRepository(
    private val remoteDataSource: InsightsRemoteDataSource,
    private val localDataSource: InsightsLocalDataSource
) {

    fun getStatistic(period: Period) = remoteDataSource.getStatistic(period)
}