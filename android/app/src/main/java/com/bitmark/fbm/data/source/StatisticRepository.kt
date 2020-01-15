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
import io.reactivex.schedulers.Schedulers


class StatisticRepository(
    private val remoteDataSource: StatisticRemoteDataSource,
    private val localDataSource: StatisticLocalDataSource
) : Repository {

    fun listUsageStatistic(period: Period, periodStartedAtSec: Long): Single<List<SectionR>> {
        val range = period.toPeriodRangeSec(periodStartedAtSec)
        return localDataSource.checkStoredUsageStatistic(range.first, range.last)
            .flatMap { stored ->
                if (stored) {
                    localDataSource.listUsageStatistic(period, periodStartedAtSec)
                } else {
                    listRemoteUsageStatistic(
                        period,
                        periodStartedAtSec
                    ).andThen(localDataSource.listUsageStatistic(period, periodStartedAtSec))
                }
            }
    }

    private fun listRemoteUsageStatistic(
        period: Period,
        periodStartedAtSec: Long
    ) = remoteDataSource.listUsageStatistic(
        period,
        periodStartedAtSec
    ).flatMapCompletable { statistics ->
        val range = period.toPeriodRangeSec(periodStartedAtSec)
        localDataSource.saveUsageStatistics(statistics)
            .flatMapCompletable { localDataSource.saveUsageCriteria(range.first, range.last) }
    }

    fun getInsightData() = remoteDataSource.getInsightData()
        .observeOn(Schedulers.io())
        .onErrorResumeNext { localDataSource.getInsightData() }
        .flatMap { insightData ->
            localDataSource.saveInsightData(insightData).andThen(Single.just(insightData))
        }

}