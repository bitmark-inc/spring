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
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.ReactionR
import io.reactivex.Completable
import io.reactivex.Single

@Dao
abstract class ReactionDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract fun save(reactions: List<ReactionR>): Completable

    @Query("DELETE FROM Reaction")
    abstract fun delete(): Completable

    @Query("SELECT * FROM Reaction WHERE timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrdered(
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<ReactionR>>

    @Query("SELECT * FROM Reaction WHERE reaction NOT IN (:exceptTypes) AND timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedExcept(
        exceptTypes: Array<Reaction>,
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<ReactionR>>

    @Query("SELECT * FROM Reaction WHERE reaction = :reaction AND timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedByType(
        reaction: Reaction,
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<ReactionR>>

}