/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bitmark.fbm.data.model.entity.LocationR
import io.reactivex.Completable
import io.reactivex.Single

@Dao
abstract class LocationDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    abstract fun save(location: LocationR): Completable

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    abstract fun save(locations: List<LocationR>): Completable

    @Query("SELECT * FROM Location WHERE created_at BETWEEN :startedAtSec AND :endedAtSec ORDER BY created_at DESC LIMIT :limit")
    abstract fun listOrdered(
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<LocationR>>

    @Query("SELECT * FROM Location WHERE name IN (:names) AND created_at BETWEEN :startedAtSec AND :endedAtSec ORDER BY created_at DESC LIMIT :limit")
    abstract fun listOrderedByNames(
        names: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<LocationR>>

    @Query("SELECT id FROM Location WHERE name IN (:names)")
    abstract fun listIdByNames(names: List<String>): Single<List<String>>

    @Query("DELETE FROM Location")
    abstract fun delete(): Completable
}