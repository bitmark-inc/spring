/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.dao

import androidx.room.*
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostR
import com.bitmark.fbm.data.model.entity.PostType
import io.reactivex.Completable
import io.reactivex.Single

@Dao
abstract class PostDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract fun save(post: PostR): Completable

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract fun save(posts: List<PostR>): Completable

    @Query("DELETE FROM Post")
    abstract fun delete(): Completable

    @Transaction
    @Query("SELECT * FROM Post WHERE type = :type AND timestamp BETWEEN :from AND :to ORDER BY timestamp DESC")
    abstract fun listOrderedPostByType(type: PostType, from: Long, to: Long): Single<List<PostData>>

    @Transaction
    @Query("SELECT * FROM Post WHERE instr(tags, :tag) AND timestamp BETWEEN :from AND :to ORDER BY timestamp DESC")
    abstract fun listOrderedPostByTag(tag: String, from: Long, to: Long): Single<List<PostData>>

    @Transaction
    @Query("SELECT * FROM Post WHERE location_name = :location AND timestamp BETWEEN :from AND :to ORDER BY timestamp DESC")
    abstract fun listOrderedPostByLocation(
        location: String,
        from: Long,
        to: Long
    ): Single<List<PostData>>
}