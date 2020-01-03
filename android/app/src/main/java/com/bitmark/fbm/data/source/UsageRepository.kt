/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.ext.onNetworkErrorResumeNext
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostR
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.ReactionR
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource
import io.reactivex.Single
import io.reactivex.functions.BiConsumer


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun listPost(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.checkPostStored(startedAtSec, endedAtSec).flatMap { stored ->
            if (stored) {
                localDataSource.listPost(startedAtSec, endedAtSec, limit)
            } else {
                syncPosts(
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            }
        }.onNetworkErrorResumeNext { localDataSource.listPost(startedAtSec, endedAtSec, limit) }

    private fun syncPosts(startedAtSec: Long, endedAtSec: Long, limit: Int) =
        remoteDataSource.listPost(
            startedAtSec,
            endedAtSec
        ).flatMap { posts ->
            if (posts.isEmpty()) {
                Single.just(listOf())
            } else {
                localDataSource.savePosts(posts)
                    .andThen(localDataSource.saveListPostCriteria(startedAtSec, endedAtSec))
                    .andThen(
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
        limit: Int = 20
    ) = localDataSource.checkPostWTypeStored(type, startedAtSec, endedAtSec).flatMap { stored ->
        if (stored) {
            localDataSource.listPostByType(type, startedAtSec, endedAtSec, limit)
        } else {
            syncPostsByType(
                type,
                startedAtSec,
                endedAtSec,
                limit
            ).onNetworkErrorResumeNext {
                localDataSource.listPostByType(
                    type,
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            }
        }
    }

    private fun syncPostsByType(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<PostData>> {
        var loopEndedSec = endedAtSec
        val streamFun =
            fun(startedAtSec: Long, endedAtSec: Long, thresholdEndedAt: Long) =
                remoteDataSource.listPost(
                    startedAtSec,
                    endedAtSec
                ).flatMap { remotePosts ->
                    if (remotePosts.isEmpty()) {
                        Single.just(Pair(listOf(), listOf()))
                    } else {
                        loopEndedSec = remotePosts.minBy { p -> p.timestampSec }!!.timestampSec - 1
                        localDataSource.savePosts(remotePosts)
                            .andThen(
                                localDataSource.listPostByType(
                                    type,
                                    startedAtSec,
                                    thresholdEndedAt,
                                    limit
                                )
                            ).flatMap { filterPosts ->
                                if (filterPosts.isEmpty()) {
                                    Single.just(Pair(remotePosts, listOf()))
                                } else {
                                    localDataSource.saveListPostWTypeCriteria(
                                        type,
                                        startedAtSec,
                                        thresholdEndedAt
                                    ).andThen(Single.just(Pair(remotePosts, filterPosts)))
                                }
                            }
                    }
                }

        return Single.create { emt ->
            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(object :
                BiConsumer<Pair<List<PostR>, List<PostData>>, Throwable> {
                override fun accept(p: Pair<List<PostR>, List<PostData>>?, e: Throwable?) {
                    if (e != null) {
                        emt.onError(e)
                    } else {
                        val remotePosts = p!!.first
                        val filteredPosts = p.second
                        if (remotePosts.isNotEmpty() && filteredPosts.isEmpty() && loopEndedSec > startedAtSec) {
                            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(this)
                        } else {
                            emt.onSuccess(filteredPosts)
                        }
                    }
                }
            })
        }
    }

    fun listPostByTags(
        tags: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ): Single<List<PostData>> {
        return localDataSource.checkPostWTagsStored(tags, startedAtSec, endedAtSec)
            .flatMap { stored ->
                if (stored) {
                    listStoredPostByTags(tags, startedAtSec, endedAtSec, limit)
                } else {
                    syncPostsByTag(
                        tags,
                        startedAtSec,
                        endedAtSec,
                        limit
                    ).onNetworkErrorResumeNext {
                        listStoredPostByTags(
                            tags,
                            startedAtSec,
                            endedAtSec,
                            limit
                        )
                    }
                }
            }
    }

    private fun syncPostsByTag(
        tags: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<PostData>> {
        var loopEndedSec = endedAtSec
        val streamFun =
            fun(startedAtSec: Long, endedAtSec: Long, thresholdEndedAt: Long) =
                remoteDataSource.listPost(startedAtSec, endedAtSec)
                    .flatMap { remotePosts ->
                        if (remotePosts.isEmpty()) {
                            Single.just(Pair(listOf(), listOf()))
                        } else {
                            loopEndedSec =
                                remotePosts.minBy { p -> p.timestampSec }!!.timestampSec - 1
                            localDataSource.savePosts(remotePosts).andThen(
                                listStoredPostByTags(tags, startedAtSec, thresholdEndedAt, limit)
                            ).flatMap { filteredPosts ->
                                if (filteredPosts.isEmpty()) {
                                    Single.just(Pair(remotePosts, listOf()))
                                } else {
                                    localDataSource.saveListPostWTagsCriteria(
                                        tags,
                                        startedAtSec,
                                        thresholdEndedAt
                                    ).andThen(Single.just(Pair(remotePosts, filteredPosts)))
                                }
                            }
                        }
                    }

        return Single.create { emt ->
            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(object :
                BiConsumer<Pair<List<PostR>, List<PostData>>, Throwable> {
                override fun accept(p: Pair<List<PostR>, List<PostData>>?, e: Throwable?) {
                    if (e != null) {
                        emt.onError(e)
                    } else {
                        val remotePosts = p!!.first
                        val filteredPosts = p.second
                        if (remotePosts.isNotEmpty() && filteredPosts.isEmpty() && loopEndedSec > startedAtSec) {
                            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(this)
                        } else {
                            emt.onSuccess(filteredPosts!!)
                        }
                    }
                }

            })
        }
    }

    private fun listStoredPostByTags(
        tags: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<PostData>> {
        val streams = tags.map { tag ->
            localDataSource.listPostByTag(tag, startedAtSec, endedAtSec, limit)
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
            val result = collection.distinctBy { it.timestampSec }.toMutableList()
            result.sortByDescending { it.timestampSec }
            result
        }
    }

    fun listPostByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) = localDataSource.checkPostWLocationsStored(
        locationNames,
        startedAtSec,
        endedAtSec
    ).flatMap { stored ->
        if (stored) {
            localDataSource.listPostByLocations(
                locationNames,
                startedAtSec,
                endedAtSec,
                limit
            )
        } else {
            syncPostsByLocationNames(
                locationNames,
                startedAtSec,
                endedAtSec,
                limit
            ).onNetworkErrorResumeNext {
                localDataSource.listPostByLocations(
                    locationNames,
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            }
        }
    }

    private fun syncPostsByLocationNames(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<PostData>> {
        var loopEndedSec = endedAtSec
        val streamFun =
            fun(startedAtSec: Long, endedAtSec: Long, thresholdEndedAt: Long) =
                remoteDataSource.listPost(startedAtSec, endedAtSec).flatMap { remotePosts ->
                    if (remotePosts.isEmpty()) {
                        Single.just(Pair(listOf(), listOf()))
                    } else {
                        loopEndedSec = remotePosts.minBy { p -> p.timestampSec }!!.timestampSec - 1
                        localDataSource.savePosts(remotePosts).andThen(
                            localDataSource.listPostByLocations(
                                locationNames,
                                startedAtSec,
                                thresholdEndedAt,
                                limit
                            )
                        ).flatMap { filteredPosts ->
                            if (filteredPosts.isEmpty()) {
                                Single.just(Pair(remotePosts, listOf()))
                            } else {
                                localDataSource.saveListPostWLocationsCriteria(
                                    locationNames,
                                    startedAtSec,
                                    thresholdEndedAt
                                ).andThen(Single.just(Pair(remotePosts, filteredPosts)))
                            }
                        }
                    }
                }

        return Single.create { emt ->
            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(object :
                BiConsumer<Pair<List<PostR>, List<PostData>>, Throwable> {
                override fun accept(p: Pair<List<PostR>, List<PostData>>?, e: Throwable?) {
                    if (e != null) {
                        emt.onError(e)
                    } else {
                        val remotePosts = p!!.first
                        val filteredPosts = p.second
                        if (remotePosts.isNotEmpty() && filteredPosts.isEmpty() && loopEndedSec > startedAtSec) {
                            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(this)
                        } else {
                            emt.onSuccess(filteredPosts)
                        }
                    }
                }

            })
        }
    }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        localDataSource.checkReactionStored(startedAtSec, endedAtSec).flatMap { stored ->
            if (stored) {
                localDataSource.listReaction(startedAtSec, endedAtSec, limit)
            } else {
                syncReaction(
                    startedAtSec,
                    endedAtSec,
                    limit
                ).onNetworkErrorResumeNext {
                    localDataSource.listReaction(
                        startedAtSec,
                        endedAtSec,
                        limit
                    )
                }
            }
        }

    private fun syncReaction(
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<ReactionR>> {
        var loopEndedSec = endedAtSec
        val streamFun =
            fun(startedAtSec: Long, endedAtSec: Long, thresholdEndedAt: Long) =
                remoteDataSource.listReaction(startedAtSec, endedAtSec).flatMap { remoteReactions ->
                    if (remoteReactions.isEmpty()) {
                        Single.just(Pair(listOf(), listOf()))
                    } else {
                        loopEndedSec =
                            remoteReactions.minBy { r -> r.timestampSec }!!.timestampSec - 1
                        localDataSource.saveReactions(remoteReactions)
                            .andThen(
                                localDataSource.listReaction(
                                    startedAtSec,
                                    thresholdEndedAt,
                                    limit
                                )
                            )
                            .flatMap { filteredReactions ->
                                if (filteredReactions.isEmpty()) {
                                    Single.just(Pair(remoteReactions, listOf()))
                                } else {
                                    localDataSource.saveReactionCriteria(
                                        startedAtSec,
                                        thresholdEndedAt
                                    )
                                        .andThen(
                                            Single.just(
                                                Pair(
                                                    remoteReactions,
                                                    filteredReactions
                                                )
                                            )
                                        )
                                }
                            }
                    }
                }

        return Single.create { emt ->
            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(object :
                BiConsumer<Pair<List<ReactionR>, List<ReactionR>>, Throwable> {
                override fun accept(p: Pair<List<ReactionR>, List<ReactionR>>?, e: Throwable?) {
                    if (e != null) {
                        emt.onError(e)
                    } else {
                        val remoteReactions = p!!.first
                        val filteredReactions = p.second
                        if (remoteReactions.isNotEmpty() && filteredReactions.isEmpty() && loopEndedSec > startedAtSec) {
                            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(this)
                        } else {
                            emt.onSuccess(filteredReactions)
                        }
                    }
                }

            })
        }
    }

    fun getPresignUrl(uri: String) = remoteDataSource.getPresignedUrl(uri)

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) = localDataSource.checkReactionWTypeStored(
        reaction,
        startedAtSec,
        endedAtSec
    ).flatMap { stored ->
        if (stored) {
            localDataSource.listReactionByType(
                reaction,
                startedAtSec,
                endedAtSec,
                limit
            )
        } else {
            syncReactionByType(reaction, startedAtSec, endedAtSec, limit).onNetworkErrorResumeNext {
                localDataSource.listReactionByType(
                    reaction,
                    startedAtSec,
                    endedAtSec,
                    limit
                )
            }
        }
    }

    private fun syncReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int
    ): Single<List<ReactionR>> {
        var loopEndedSec = endedAtSec
        val streamFun =
            fun(startedAtSec: Long, endedAtSec: Long, thresholdEndedAt: Long) =
                remoteDataSource.listReaction(startedAtSec, endedAtSec)
                    .flatMap { remoteReactions ->
                        if (remoteReactions.isEmpty()) {
                            Single.just(Pair(listOf(), listOf()))
                        } else {
                            loopEndedSec =
                                remoteReactions.minBy { r -> r.timestampSec }!!.timestampSec - 1
                            localDataSource.saveReactions(remoteReactions)
                                .andThen(
                                    localDataSource.listReactionByType(
                                        reaction,
                                        startedAtSec,
                                        thresholdEndedAt,
                                        limit
                                    )
                                ).flatMap { filteredReactions ->
                                    if (filteredReactions.isEmpty()) {
                                        Single.just(Pair(remoteReactions, listOf()))
                                    } else {
                                        localDataSource.saveReactionWTypeCriteria(
                                            reaction,
                                            startedAtSec,
                                            thresholdEndedAt
                                        ).andThen(
                                            Single.just(
                                                Pair(
                                                    remoteReactions,
                                                    filteredReactions
                                                )
                                            )
                                        )
                                    }
                                }
                        }
                    }

        return Single.create { emt ->
            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(object :
                BiConsumer<Pair<List<ReactionR>, List<ReactionR>>, Throwable> {
                override fun accept(p: Pair<List<ReactionR>, List<ReactionR>>?, e: Throwable?) {
                    if (e != null) {
                        emt.onError(e)
                    } else {
                        val remoteReactions = p!!.first
                        val filteredReactions = p.second
                        if (remoteReactions.isNotEmpty() && filteredReactions.isEmpty() && loopEndedSec > startedAtSec) {
                            streamFun(startedAtSec, loopEndedSec, endedAtSec).subscribe(this)
                        } else {
                            emt.onSuccess(filteredReactions)
                        }
                    }
                }

            })
        }
    }

}