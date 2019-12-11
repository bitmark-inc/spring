/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.data.source.local.StatisticLocalDataSource
import com.bitmark.fbm.data.source.remote.StatisticRemoteDataSource
import io.reactivex.Single


class StatisticRepository(
    private val remoteDataSource: StatisticRemoteDataSource,
    private val localDataSource: StatisticLocalDataSource
) : Repository {

    fun listStatistic(sectionNames: Array<SectionName>, period: Period, periodStartedAt: Long) =
        localDataSource.listStatistic(sectionNames, period, periodStartedAt).flatMap { sections ->
            if (sections.isEmpty()) {
                listRemoteStatistic(
                    sectionNames,
                    period,
                    periodStartedAt
                ).flatMap { localDataSource.listStatistic(sectionNames, period, periodStartedAt) }
            } else {
                Single.just(sections)
            }
        }

    private fun listRemoteStatistic(
        sectionNames: Array<SectionName>,
        period: Period,
        periodStartedAt: Long
    ) = remoteDataSource.listStatistic(
        sectionNames,
        period,
        periodStartedAt
    ).flatMap { statistics ->
        localDataSource.saveStatistics(statistics)
    }
}