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
import com.bitmark.fbm.data.model.entity.CommentR
import io.reactivex.Completable
import io.reactivex.Single


@Dao
abstract class CommentDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract fun save(comment: CommentR) : Single<Long>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract fun save(comments: List<CommentR>) : Single<List<Long>>

    @Query("DELETE FROM Comment")
    abstract fun delete(): Completable
}