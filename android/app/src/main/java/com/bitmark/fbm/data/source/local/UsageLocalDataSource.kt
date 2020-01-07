/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.ext.mapToCheckDbRecordResult
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import io.reactivex.Completable
import io.reactivex.Single
import javax.inject.Inject


class UsageLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun listPost(startedAt: Long, endedAt: Long, limit: Int = 100) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPost(startedAt, endedAt, limit)
        }

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByType(type, startedAtSec, endedAtSec, limit)
        }

    fun listPostByTag(tag: String, startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByTag(tag, startedAtSec, endedAtSec, limit)
        }

    fun listPostByLocations(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 100
    ): Single<List<PostData>> =
        listLocationIdByNames(locationNames).flatMap { ids ->
            if (ids.isEmpty()) {
                Single.just(listOf())
            } else {
                databaseApi.rxSingle { databaseGateway ->
                    databaseGateway.postDao()
                        .listOrderedPostByLocations(ids, startedAtSec, endedAtSec, limit)
                }
            }

        }

    fun savePosts(posts: List<PostR>) = databaseApi.rxSingle { databaseGateway ->
        val saveLocationStream = posts.filter { p -> p.location != null }.map { p ->
            p.location!!.applyRequiredValues(p.timestampSec)
            databaseGateway.locationDao().save(p.location!!)
        }
        if (saveLocationStream.isEmpty()) {
            Single.just(posts)
        } else {
            Completable.merge(saveLocationStream).andThen(Single.just(posts))
        }
    }.flatMap { ps ->
        databaseApi.rxSingle { databaseGateway ->
            ps.applyRequiredValues()
            databaseGateway.postDao().save(ps).andThen(Single.just(ps))
        }
    }.flatMapCompletable { ps ->
        val saveCommentStreams =
            ps.filter { p -> p.comments != null && p.comments!!.isNotEmpty() }.map { p ->
                val comments = p.comments
                comments?.applyPostId(p.timestampSec)
                saveComments(comments!!).ignoreElement()
            }
        if (saveCommentStreams.isEmpty()) {
            Completable.complete()
        } else {
            Completable.merge(saveCommentStreams)
        }
    }

    private fun saveComments(comments: List<CommentR>) =
        databaseApi.rxSingle { databaseGateway -> databaseGateway.commentDao().save(comments) }

    fun checkPostStored(startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromPostWRange(startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun checkPostWTypeStored(type: PostType, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromPostWType(type, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun checkPostWTagsStored(tags: List<String>, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromPostWTags(tags, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun checkPostWLocationsStored(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long
    ) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromPostWLocations(locationNames, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun saveListPostCriteria(startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromPostWRange(startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun saveListPostWTypeCriteria(type: PostType, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromPostWType(type, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun saveListPostWTagsCriteria(tags: List<String>, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromPostWTags(tags, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun saveListPostWLocationsCriteria(
        locationNames: List<String>,
        startedAtSec: Long,
        endedAtSec: Long
    ) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromPostWLocations(locationNames, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun saveReactions(reactions: List<ReactionR>) = databaseApi.rxCompletable { databaseGateway ->
        databaseGateway.reactionDao().save(reactions)
    }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 100) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.reactionDao().listOrderedExcept(
                arrayOf(Reaction.DOROTHY, Reaction.TOTO),
                startedAtSec,
                endedAtSec,
                limit
            )
        }

    fun checkReactionStored(startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromReactionWRange(startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun checkReactionWTypeStored(reaction: Reaction, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            val criteria = CriteriaR.fromReactionWType(reaction, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao()
                .getCriteria(criteria.query)
                .mapToCheckDbRecordResult()
        }

    fun saveReactionCriteria(startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromReactionWRange(startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun saveReactionWTypeCriteria(reaction: Reaction, startedAtSec: Long, endedAtSec: Long) =
        databaseApi.rxCompletable { databaseGateway ->
            val criteria = CriteriaR.fromReactionWType(reaction, startedAtSec, endedAtSec)
            databaseGateway.criteriaDao().save(criteria)
        }

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 100
    ) = databaseApi.rxSingle { databaseGateway ->
        databaseGateway.reactionDao().listOrderedByType(reaction, startedAtSec, endedAtSec, limit)
    }

    private fun listLocationIdByNames(names: List<String>) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.locationDao().listIdByNames(names)
        }

}