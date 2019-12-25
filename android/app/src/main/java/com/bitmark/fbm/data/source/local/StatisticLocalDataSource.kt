/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.data.model.entity.SectionR
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import javax.inject.Inject


class StatisticLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun listUsage(period: Period, periodStartedAt: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.sectionDao().listBy(
                arrayOf(SectionName.REACTION, SectionName.POST),
                period,
                periodStartedAt
            )
        }

    fun listInsights(period: Period, periodStartedAt: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.sectionDao().listBy(
                arrayOf(SectionName.FB_INCOME, SectionName.SENTIMENT),
                period,
                periodStartedAt
            )
        }

    fun saveStatistics(sections: List<SectionR>) = databaseApi.rxSingle { databaseGateway ->
        databaseGateway.sectionDao().save(sections)
    }
}