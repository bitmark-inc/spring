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
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.data.model.entity.SectionR
import io.reactivex.Completable
import io.reactivex.Single


@Dao
abstract class SectionDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    abstract fun save(section: SectionR): Single<Long>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    abstract fun save(sections: List<SectionR>): Single<List<Long>>

    @Query("DELETE FROM Section")
    abstract fun delete(): Completable

    @Query("SELECT * FROM Section WHERE section_name IN (:sectionNames) AND period = :period AND period_started_at = :periodStartedAt")
    abstract fun listBy(
        sectionNames: Array<SectionName>,
        period: Period,
        periodStartedAt: Long
    ): Single<List<SectionR>>
}