/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.locationdetail

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.entity.LocationR
import com.bitmark.fbm.data.source.InsightsRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.LocationModelView


class LocationDetailViewModel(
    lifecycle: Lifecycle,
    private val insightsRepo: InsightsRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val listLocationLiveData = CompositeLiveData<List<LocationModelView>>()

    private var lastEndedAtSec = -1L

    fun listLocation(startedAtSec: Long, endedAtSec: Long) {
        listLocationLiveData.add(
            rxLiveDataTransformer.single(
                listLocationStream(
                    startedAtSec,
                    endedAtSec
                )
            )
        )
    }

    fun listNextLocation(startedAtSec: Long) {
        listLocationLiveData.add(
            rxLiveDataTransformer.single(
                listLocationStream(
                    startedAtSec,
                    lastEndedAtSec - 1
                )
            )
        )
    }

    private fun listLocationStream(startedAtSec: Long, endedAtSec: Long) =
        insightsRepo.listLocation(startedAtSec, endedAtSec).map(mapLocations())

    fun listLocationByNames(names: List<String>, startedAtSec: Long, endedAtSec: Long) {
        listLocationLiveData.add(
            rxLiveDataTransformer.single(
                listLocationByNamesStream(
                    names,
                    startedAtSec,
                    endedAtSec
                )
            )
        )
    }

    fun listNextLocationByNames(name: List<String>, startedAtSec: Long) {
        listLocationLiveData.add(
            rxLiveDataTransformer.single(
                listLocationByNamesStream(
                    name,
                    startedAtSec,
                    lastEndedAtSec - 1
                )
            )
        )
    }

    private fun listLocationByNamesStream(names: List<String>, startedAtSec: Long, endedAtSec: Long) =
        insightsRepo.listLocationByNames(names, startedAtSec, endedAtSec).map(mapLocations())

    private fun mapLocations(): (List<LocationR>) -> List<LocationModelView> =
        { locations ->
            if (locations.isNotEmpty()) {
                lastEndedAtSec = locations.last().createdAtSec
            }
            locations.map { l -> LocationModelView.newInstance(l) }
        }
}