/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource
import io.reactivex.Single


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun listPost(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listPost(startedAtSec, endedAtSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePost(startedAtSec, endedAtSec, limit).andThen(
                    localDataSource.listPost(
                        startedAtSec,
                        endedAtSec
                    )
                )
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePost(startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listPost(startedAtSec, endedAtSec, limit).flatMapCompletable { posts ->
            localDataSource.savePosts(posts)
        }

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listPostByType(type, startedAtSec, endedAtSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByType(type, startedAtSec, endedAtSec, limit).andThen(
                    localDataSource.listPostByType(
                        type,
                        startedAtSec,
                        endedAtSec
                    )
                )
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByType(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ) =
        remoteDataSource.listPostByType(type, startedAtSec, endedAtSec, limit)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByTag(tag: String, fromSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listPostByTag(tag, fromSec, endedAtSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByTag(tag, fromSec, endedAtSec, limit).andThen(
                    localDataSource.listPostByTag(
                        tag,
                        fromSec,
                        endedAtSec
                    )
                )
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByTag(tag: String, startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listPostByTag(tag, startedAtSec, endedAtSec, limit)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByLocation(location: String, fromSec: Long, toSec: Long, limit: Int = 20) =
        localDataSource.listPostByLocation(location, fromSec, toSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByLocation(
                    location,
                    fromSec,
                    toSec,
                    limit
                ).andThen(localDataSource.listPostByLocation(location, fromSec, toSec))
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByLocation(
        location: String,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ) =
        remoteDataSource.listPostByLocation(location, startedAtSec, endedAtSec, limit)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listReaction(startedAtSec, endedAtSec, limit).flatMap { reactions ->
            if (reactions.isEmpty()) {
                remoteDataSource.listReaction(startedAtSec, endedAtSec, limit).flatMap { rs ->
                    if (rs.isEmpty()) {
                        Single.just(rs)
                    } else {
                        localDataSource.saveReactions(rs)
                            .andThen(localDataSource.listReaction(startedAtSec, endedAtSec, limit))
                    }
                }
            } else {
                Single.just(reactions)
            }
        }

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) =
        localDataSource.listReactionByType(
            reaction,
            startedAtSec,
            endedAtSec,
            limit
        ).flatMap { reactions ->
            if (reactions.isEmpty()) {
                remoteDataSource.listReactionByType(reaction, startedAtSec, endedAtSec, limit)
                    .flatMap { rs ->
                        if (rs.isEmpty()) {
                            Single.just(rs)
                        } else {
                            localDataSource.saveReactions(rs)
                                .andThen(
                                    localDataSource.listReactionByType(
                                        reaction,
                                        startedAtSec,
                                        endedAtSec,
                                        limit
                                    )
                                )
                        }
                    }
            } else {
                Single.just(reactions)
            }
        }

}