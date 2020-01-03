/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionR
import com.bitmark.fbm.data.model.entity.toPeriodRangeSec
import com.bitmark.fbm.data.source.local.StatisticLocalDataSource
import com.bitmark.fbm.data.source.remote.StatisticRemoteDataSource
import io.reactivex.Single


class StatisticRepository(
    private val remoteDataSource: StatisticRemoteDataSource,
    private val localDataSource: StatisticLocalDataSource
) : Repository {

    fun listUsage(period: Period, periodStartedAtSec: Long): Single<List<SectionR>> {
        val range = period.toPeriodRangeSec(periodStartedAtSec)
        return localDataSource.checkUsageStored(range.first, range.last).flatMap { stored ->
            if (stored) {
                localDataSource.listUsage(period, periodStartedAtSec)
            } else {
                listRemoteUsage(
                    period,
                    periodStartedAtSec
                ).andThen(localDataSource.listUsage(period, periodStartedAtSec))
            }
        }
    }

    fun listInsights(period: Period, periodStartedAtSec: Long): Single<List<SectionR>> {
        val range = period.toPeriodRangeSec(periodStartedAtSec)
        return localDataSource.checkInsightStored(range.first, range.last).flatMap { stored ->
            if (stored) {
                localDataSource.listInsights(period, periodStartedAtSec)
            } else {
                listRemoteInsights(period, periodStartedAtSec).andThen(
                    localDataSource.listInsights(
                        period,
                        periodStartedAtSec
                    )
                )
            }
        }
    }

    private fun listRemoteUsage(
        period: Period,
        periodStartedAtSec: Long
    ) = remoteDataSource.listUsage(
        period,
        periodStartedAtSec
    ).flatMapCompletable { statistics ->
        val range = period.toPeriodRangeSec(periodStartedAtSec)
        localDataSource.saveStatistics(statistics)
            .flatMapCompletable { localDataSource.saveUsageCriteria(range.first, range.last) }
    }

    private fun listRemoteInsights(period: Period, periodStartedAtSec: Long) =
        remoteDataSource.listInsights(
            period,
            periodStartedAtSec
        ).flatMapCompletable { statistics ->
            val range = period.toPeriodRangeSec(periodStartedAtSec)
            localDataSource.saveStatistics(statistics)
                .flatMapCompletable { localDataSource.saveInsightCriteria(range.first, range.last) }
        }
}