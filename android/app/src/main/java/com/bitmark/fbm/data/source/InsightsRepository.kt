/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.source.local.InsightsLocalDataSource
import com.bitmark.fbm.data.source.remote.InsightsRemoteDataSource
import io.reactivex.Single


class InsightsRepository(
    private val remoteDataSource: InsightsRemoteDataSource,
    private val localDataSource: InsightsLocalDataSource
) {

    fun listLocation(startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        localDataSource.listLocation(startedAtSec, endedAtSec).flatMap { locations ->
            if (locations.isEmpty()) {
                listRemoteLocation(startedAtSec, endedAtSec, limit).andThen(
                    localDataSource.listLocation(
                        startedAtSec,
                        endedAtSec
                    )
                )
            } else {
                Single.just(locations)
            }
        }

    private fun listRemoteLocation(startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listLocation(
            startedAtSec,
            endedAtSec,
            limit
        ).flatMapCompletable { locations ->
            localDataSource.saveLocations(locations)
        }

    fun listLocationByNames(names: List<String>, startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        localDataSource.listLocationByNames(names, startedAtSec, endedAtSec).flatMap { locations ->
            if (locations.isEmpty()) {
                listRemoteLocationByName(names, startedAtSec, endedAtSec, limit).andThen(
                    localDataSource.listLocationByNames(
                        names,
                        startedAtSec,
                        endedAtSec
                    )
                )
            } else {
                Single.just(locations)
            }
        }

    private fun listRemoteLocationByName(
        names: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ) =
        remoteDataSource.listLocationByNames(
            names,
            startedAtSec,
            endedAtSec,
            limit
        ).flatMapCompletable { locations ->
            localDataSource.saveLocations(locations)
        }

}