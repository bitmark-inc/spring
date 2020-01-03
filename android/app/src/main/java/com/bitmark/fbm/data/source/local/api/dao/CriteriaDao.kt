/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bitmark.fbm.data.model.entity.CriteriaR
import io.reactivex.Completable
import io.reactivex.Single

@Dao
abstract class CriteriaDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    abstract fun save(criteria: CriteriaR): Completable

    @Query("DELETE FROM Criteria")
    abstract fun delete(): Completable

    @Query("SELECT * FROM Criteria WHERE `query` = :query")
    abstract fun getCriteria(query: String): Single<CriteriaR>
}