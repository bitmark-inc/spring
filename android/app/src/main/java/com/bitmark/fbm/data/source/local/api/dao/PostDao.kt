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
    @Query("SELECT * FROM Post WHERE timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedPost(
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<PostData>>

    @Transaction
    @Query("SELECT * FROM Post WHERE type = :type AND timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedPostByType(
        type: PostType,
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<PostData>>

    @Transaction
    @Query("SELECT * FROM Post WHERE instr(tags, :tags) AND timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedPostByTags(
        tags: List<String>,
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<PostData>>

    @Transaction
    @Query("SELECT * FROM Post WHERE location_name IN (:locations) AND timestamp BETWEEN :startedAt AND :endedAt ORDER BY timestamp DESC LIMIT :limit")
    abstract fun listOrderedPostByLocations(
        locations: List<String>,
        startedAt: Long,
        endedAt: Long,
        limit: Int
    ): Single<List<PostData>>
}