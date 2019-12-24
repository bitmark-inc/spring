/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.model.entity.LocationR
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import javax.inject.Inject


class InsightsLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun listLocation(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.locationDao().listOrdered(startedAtSec, endedAtSec, limit)
        }

    fun listLocationByNames(names: List<String>, startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.locationDao().listOrderedByNames(names, startedAtSec, endedAtSec, limit)
        }

    fun saveLocations(locations: List<LocationR>) = databaseApi.rxCompletable { databaseGateway ->
        databaseGateway.locationDao().save(locations)
    }

}