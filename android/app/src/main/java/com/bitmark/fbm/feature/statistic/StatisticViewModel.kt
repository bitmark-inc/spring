/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.data.source.StatisticRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.SectionModelView
import io.reactivex.schedulers.Schedulers
import java.util.*


class StatisticViewModel(
    lifecycle: Lifecycle,
    private val statisticRepo: StatisticRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) :
    BaseViewModel(lifecycle) {

    internal val getStatisticLiveData = CompositeLiveData<List<SectionModelView>>()

    fun getStatistic(@Statistic.Type type: String, period: Period, periodStartedTime: Long) {
        getStatisticLiveData.add(
            rxLiveDataTransformer.single(
                statisticRepo.listStatistic(
                    if (type == Statistic.USAGE) {
                        arrayOf(
                            SectionName.POST,
                            SectionName.REACTION,
                            SectionName.MESSAGE
                        )
                    } else {
                        arrayOf(
                            SectionName.AD_INTEREST,
                            SectionName.ADVERTISER,
                            SectionName.LOCATION
                        )
                    }
                    , period, periodStartedTime
                ).observeOn(Schedulers.computation()).map { sections ->
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