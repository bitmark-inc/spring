/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.MediaType
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.functions.BiConsumer


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun listPost(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listPost(startedAtSec, endedAtSec, limit).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePost(startedAtSec, endedAtSec).andThen(
                    localDataSource.listPost(
                        startedAtSec,
                        endedAtSec,
                        limit
                    )
                )
            } else {
                Single.just(posts)
            }
        }.flatMap { posts -> applyPresignedUrl(posts) }

    private fun listRemotePost(startedAtSec: Long, endedAtSec: Long) =
        remoteDataSource.listPost(startedAtSec, endedAtSec).flatMapCompletable { posts ->
            localDataSource.savePosts(posts)
        }

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listPostByType(type, startedAtSec, endedAtSec, limit).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByType(type, startedAtSec, endedAtSec).andThen(
                    localDataSource.listPostByType(
                        type,
                        startedAtSec,
                        endedAtSec,
                        limit
                    )
                )
            } else {
                Single.just(posts)
            }
        }.flatMap { posts -> applyPresignedUrl(posts) }

    private fun listRemotePostByType(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long
    ) = remoteDataSource.listPostByType(
        type,
        startedAtSec,
        endedAtSec
    ).flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByTags(
        tags: List<String>,
        fromSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ): Single<List<PostData>> {
        val streams = tags.map { tag ->
            localDataSource.listPostByTag(tag, fromSec, endedAtSec, limit).flatMap { posts ->
                if (posts.isEmpty()) {
                    listRemotePostByTag(tag, fromSec, endedAtSec).andThen(
                        localDataSource.listPostByTag(
                            tag,
                            fromSec,
                            endedAtSec,
                            limit
                        )
                    )
                } else {
                    Single.just(posts)
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
        }.flatMap { posts -> applyPresignedUrl(posts) }
    }

    private fun listRemotePostByTag(tag: String, startedAtSec: Long, endedAtSec: Long) =
        remoteDataSource.listPostByTag(tag, startedAtSec, endedAtSec)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByLocationNames(
        locationNames: List<String>,
        fromSec: Long,
        toSec: Long,
        limit: Int = 20
    ) =
        localDataSource.listPostByLocations(locationNames, fromSec, toSec, limit).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByLocationNames(
                    locationNames,
                    fromSec,
                    toSec
                ).andThen(localDataSource.listPostByLocations(locationNames, fromSec, toSec, limit))
            } else {
                Single.just(posts)
            }
        }.flatMap { posts -> applyPresignedUrl(posts) }

    private fun listRemotePostByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long
    ) = remoteDataSource.listPostByLocationNames(
        locationNames,
        startedAtSec,
        endedAtSec
    ).flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.listReaction(startedAtSec, endedAtSec, limit).flatMap { reactions ->
            if (reactions.isEmpty()) {
                remoteDataSource.listReaction(startedAtSec, endedAtSec).flatMap { rs ->
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

    private fun applyPresignedUrl(posts: List<PostData>): Single<List<PostData>> {
        val streams = posts.filter { p -> p.mediaType == MediaType.VIDEO && p.source != null }
            .map { post ->
                remoteDataSource.getPresignedUrl(post.source!!)
                    .onErrorResumeNext { e ->
                        if (e is IllegalAccessException) {
                            Single.just("")
                        } else {
                            Single.error<String>(e)
                        }
                    }.map { presignedUrl -> post.post.mediaData?.get(0)?.source = presignedUrl }
                    .ignoreElement()
            }
        return Completable.mergeDelayError(streams).andThen(Single.just(posts))
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
                remoteDataSource.listReactionByType(reaction, startedAtSec, endedAtSec)
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