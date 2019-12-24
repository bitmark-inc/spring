/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.source.local.StatisticLocalDataSource
import com.bitmark.fbm.data.source.remote.StatisticRemoteDataSource
import io.reactivex.Single


class StatisticRepository(
    private val remoteDataSource: StatisticRemoteDataSource,
    private val localDataSource: StatisticLocalDataSource
) : Repository {

    fun listUsage(period: Period, periodStartedAtSec: Long) =
        localDataSource.listUsage(period, periodStartedAtSec).flatMap { sections ->
            if (sections.isEmpty()) {
                listRemoteUsage(
                    period,
                    periodStartedAtSec
                ).flatMap { localDataSource.listUsage(period, periodStartedAtSec) }
            } else {
                Single.just(sections)
            }
        }

    fun listInsights(period: Period, periodStartedAtSec: Long) =
        localDataSource.listInsights(period, periodStartedAtSec).flatMap { sections ->
            if (sections.isEmpty()) {
                listRemoteInsights(
                    period,
                    periodStartedAtSec
                ).flatMap { localDataSource.listInsights(period, periodStartedAtSec) }
            } else {
                Single.just(sections)
            }
        }

    private fun listRemoteUsage(
        period: Period,
        periodStartedAtSec: Long
    ) = remoteDataSource.listUsage(
        period,
        periodStartedAtSec
    ).flatMap { statistics ->
        localDataSource.saveStatistics(statistics)
    }

    private fun listRemoteInsights(period: Period, periodStartedAtSec: Long) =
        remoteDataSource.listInsights(
            period,
            periodStartedAtSec
        ).flatMap { statistics ->
            localDataSource.saveStatistics(statistics)
        }
}