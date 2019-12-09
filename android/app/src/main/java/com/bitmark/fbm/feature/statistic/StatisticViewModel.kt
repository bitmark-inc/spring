/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.source.InsightsRepository
import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.SectionModelView
import java.util.*


class StatisticViewModel(
    lifecycle: Lifecycle,
    private val usageRepo: UsageRepository,
    private val insightsRepo: InsightsRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) :
    BaseViewModel(lifecycle) {

    internal val getStatisticLiveData = CompositeLiveData<List<SectionModelView>>()

    fun getUsageStatistic(period: Period, periodStartedTime: Long) {
        getStatisticLiveData.add(
            rxLiveDataTransformer.single(
                usageRepo.getStatistic(period).map { sections ->
                    sections.map { s ->
                        SectionModelView.newInstance(
                            s,
                            Random().nextInt(100)
                        )
                    }
                })
        )
    }

    fun getInsightsStatistic(period: Period, periodStartedTime: Long) {
        getStatisticLiveData.add(
            rxLiveDataTransformer.single(
                insightsRepo.getStatistic(period).map { sections ->
                    sections.map { s ->
                        SectionModelView.newInstance(
                            s,
                            Random().nextInt(100)
                        )
                    }
                })
        )
    }

}