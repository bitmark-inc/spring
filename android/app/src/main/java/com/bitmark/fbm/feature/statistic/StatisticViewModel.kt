/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.ext.onNetworkErrorReturn
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.data.source.StatisticRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.ext.replace
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.SectionModelView
import com.bitmark.fbm.util.modelview.order
import io.reactivex.schedulers.Schedulers
import java.util.*


class StatisticViewModel(
    lifecycle: Lifecycle,
    private val statisticRepo: StatisticRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) :
    BaseViewModel(lifecycle) {

    internal val listUsageStatisticLiveData = CompositeLiveData<List<SectionModelView>>()

    fun listUsageStatistic(period: Period, periodStartedAtSec: Long) {
        val stream =
            statisticRepo.listUsageStatistic(period, periodStartedAtSec)
                .onNetworkErrorReturn(listOf())
                .observeOn(Schedulers.computation())
                .map { usageStatistics ->
                    val defaultVMs =
                        newDefaultSectionMVs(period, periodStartedAtSec).toMutableList()
                    val vms = when {
                        usageStatistics.isEmpty() -> defaultVMs
                        usageStatistics.size == defaultVMs.size -> {
                            usageStatistics.map { s ->
                                SectionModelView.newInstance(
                                    s,
                                    Random().nextInt(100)
                                )
                            }
                        }
                        else -> {
                            val vms =
                                usageStatistics.map { s ->
                                    SectionModelView.newInstance(
                                        s,
                                        Random().nextInt(100)
                                    )
                                }
                            for (i in 0 until defaultVMs.size) {
                                val vm =
                                    vms.firstOrNull { v -> v.name == defaultVMs[i].name }
                                        ?: continue
                                defaultVMs.replace(vm, i)
                            }
                            defaultVMs
                        }
                    }.toMutableList()
                    vms.sortWith(Comparator { o1, o2 -> o2.order().compareTo(o1.order()) })
                    vms.toList()
                }
        listUsageStatisticLiveData.add(
            rxLiveDataTransformer.single(
                stream
            )
        )
    }

    private fun newDefaultSectionMVs(period: Period, periodStartedAtSec: Long) =
        listOf(
            SectionModelView.newDefaultInstance(
                SectionName.SENTIMENT,
                period,
                periodStartedAtSec
            ),
            SectionModelView.newDefaultInstance(
                SectionName.POST,
                period,
                periodStartedAtSec
            ),
            SectionModelView.newDefaultInstance(
                SectionName.REACTION,
                period,
                periodStartedAtSec
            )
        )
}