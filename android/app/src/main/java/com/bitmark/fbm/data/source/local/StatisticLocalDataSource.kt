/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.mapToCheckDbRecordResult
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.InsightData
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.data.model.newDefaultInstance
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import javax.inject.Inject


class StatisticLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun listUsageStatistic(period: Period, periodStartedAt: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.sectionDao().listBy(
                arrayOf(SectionName.SENTIMENT, SectionName.REACTION, SectionName.POST),
                period,
                periodStartedAt
            )
        }

    fun saveUsageStatistics(sections: List<SectionR>) = databaseApi.rxSingle { databaseGateway ->
        databaseGateway.sectionDao().save(sections)
    }

    fun checkStoredUsageStatistic(startedAt: Long, endedAt: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromStatisticWType("usage", startedAt, endedAt)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun saveUsageCriteria(startedAt: Long, endedAt: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            databaseGateway.criteriaDao()
                .save(CriteriaR.fromStatisticWType("usage", startedAt, endedAt))
        }

    fun saveInsightData(insightData: InsightData) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.INSIGHT_DATA, insightData)
        }

    fun getInsightData() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        val insight = sharedPrefGateway.get(
            SharedPrefApi.INSIGHT_DATA,
            String::class
        )
        if (insight.isEmpty()) {
            InsightData.newDefaultInstance()
        } else {
            newGsonInstance().fromJson<InsightData>(insight)
        }

    }
}