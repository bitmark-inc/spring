/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.ext.ignoreRemoteError
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource
import io.reactivex.Single
import io.reactivex.functions.BiConsumer


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun listPost(startedAtSec: Long, endedAtSec: Long, gapSec: Long, limit: Int = 20) =
        localDataSource.listPost(startedAtSec, endedAtSec, limit).flatMap { posts ->
            when {
                posts.isEmpty()                                  -> syncPosts(
                    startedAtSec,
                    endedAtSec,
                    limit
                )
                posts.first().timestampSec + gapSec < endedAtSec -> {
                    // missing posts due to the database cache
                    val newStartedAt = posts.first().timestampSec
                    syncPosts(newStartedAt, endedAtSec, limit).ignoreRemoteError(posts)
                }
                else                                             -> Single.just(posts)
            }
        }

    private fun syncPosts(startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listPost(
            startedAtSec,
            endedAtSec
        ).flatMap { posts ->
            if (posts.isEmpty()) {
                Single.just(listOf())
            } else {
                localDataSource.savePosts(posts).andThen(
                    localDataSource.listPost(
                        startedAtSec,
                        endedAtSec,
                        limit
                    )
                )
            }
        }

    fun listPostByType(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long,
        limit: Int = 20
    ) =
        localDataSource.listPostByType(type, startedAtSec, endedAtSec, limit).flatMap { posts ->
            when {
                posts.isEmpty()                                  -> {
                    syncPostsByType(type, startedAtSec, endedAtSec, limit)
                }
                posts.first().timestampSec + gapSec < endedAtSec -> {
                    // missing posts due to the database cache
                    val newStartedAt = posts.first().timestampSec
                    syncPostsByType(type, newStartedAt, endedAtSec, limit).ignoreRemoteError(posts)
                }
                else                                             -> Single.just(posts)
            }
        }

    private fun syncPostsByType(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ) = remoteDataSource.listPost(
        startedAtSec,
        endedAtSec
    ).flatMap { posts ->
        if (posts.isEmpty()) {
            Single.just(listOf())
        } else {
            localDataSource.savePosts(posts).andThen(
                localDataSource.listPostByType(
                    type,
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            )
        }
    }


    fun listPostByTags(
        tags: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long,
        limit: Int = 20
    ): Single<List<PostData>> {
        val streams = tags.map { tag ->
            localDataSource.listPostByTag(tag, startedAtSec, endedAtSec, limit).flatMap { posts ->
                when {
                    posts.isEmpty()                                  -> {
                        syncPostsByTag(tag, startedAtSec, endedAtSec, limit)
                    }
                    posts.first().timestampSec + gapSec < endedAtSec -> {
                        // missing posts due to the database cache
                        val newStartedAt = posts.first().timestampSec
                        syncPostsByTag(
                            tag,
                            newStartedAt,
                            endedAtSec,
                            limit
                        ).ignoreRemoteError(posts)
                    }
                    else                                             -> Single.just(posts)
                }
            }
        }
        return Single.merge(streams).collectInto(
            mutableListOf(),
            BiConsumer<MutableList<List<PostData>>, List<PostData>> { collection, data ->
                collection.add(data)
            }).map { collections ->
            val collection = mutableListOf<PostData>()
            for (c in collections) {
                collection.addAll(c)
            }
            collection.distinct()
        }
    }

    private fun syncPostsByTag(tag: String, startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listPost(startedAtSec, endedAtSec)
            .flatMap { posts ->
                if (posts.isEmpty()) {
                    Single.just(listOf())
                } else {
                    localDataSource.savePosts(posts).andThen(
                        localDataSource.listPostByTag(
                            tag,
                            startedAtSec,
                            endedAtSec,
                            limit
                        )
                    )
                }
            }

    fun listPostByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long,
        limit: Int = 20
    ) =
        localDataSource.listPostByLocations(
            locationNames,
            startedAtSec,
            endedAtSec,
            limit
        ).flatMap { posts ->
            when {
                posts.isEmpty()                                  -> {
                    syncPostsByLocationNames(locationNames, startedAtSec, endedAtSec, limit)
                }
                posts.first().timestampSec + gapSec < endedAtSec -> {
                    // missing posts due to the database cache
                    val newStartedAt = posts.first().timestampSec
                    syncPostsByLocationNames(
                        locationNames,
                        newStartedAt,
                        endedAtSec,
                        limit
                    ).ignoreRemoteError(posts)
                }
                else                                             -> Single.just(posts)

            }
        }

    private fun syncPostsByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<PostData>> = remoteDataSource.listPost(
        startedAtSec,
        endedAtSec
    ).flatMap { posts ->
        if (posts.isEmpty()) {
            Single.just(listOf())
        } else {
            localDataSource.savePosts(posts).andThen(
                localDataSource.listPostByLocations(
                    locationNames,
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            )
        }
    }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, gapSec: Long, limit: Int = 20) =
        localDataSource.listReaction(startedAtSec, endedAtSec, limit).flatMap { reactions ->
            when {
                reactions.isEmpty()                                  -> {
                    syncReaction(startedAtSec, endedAtSec, limit)
                }
                reactions.first().timestampSec + gapSec < endedAtSec -> {
                    // missing reactions due to the database cache
                    val newStartedAtSec = reactions.first().timestampSec
                    syncReaction(newStartedAtSec, endedAtSec, limit).ignoreRemoteError(reactions)
                }
                else                                                 -> {
                    Single.just(reactions)
                }
            }
        }

    private fun syncReaction(startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listReaction(startedAtSec, endedAtSec).flatMap { rs ->
            if (rs.isEmpty()) {
                Single.just(rs)
            } else {
                localDataSource.saveReactions(rs)
                    .andThen(localDataSource.listReaction(startedAtSec, endedAtSec, limit))
            }
        }

    fun getPresignUrl(uri: String) = remoteDataSource.getPresignedUrl(uri)

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long,
        limit: Int = 20
    ) =
        localDataSource.listReactionByType(
            reaction,
            startedAtSec,
            endedAtSec,
            limit
        ).flatMap { reactions ->
            when {
                reactions.isEmpty()                                  -> {
                    syncReactionByType(reaction, startedAtSec, endedAtSec, limit)
                }
                reactions.first().timestampSec + gapSec < endedAtSec -> {
                    // missing reactions due to the database cache
                    val newStartedAtSec = reactions.first().timestampSec
                    syncReactionByType(
                        reaction,
                        newStartedAtSec,
                        endedAtSec,
                        limit
                    ).ignoreRemoteError(reactions)
                }
                else                                                 -> {
                    Single.just(reactions)
                }
            }
        }

    private fun syncReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ) =
        remoteDataSource.listReaction(startedAtSec, endedAtSec)
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

}