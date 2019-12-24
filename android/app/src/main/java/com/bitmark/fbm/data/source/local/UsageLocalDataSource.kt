/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

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

    fun listPost(startedAt: Long, endedAt: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPost(startedAt, endedAt, limit)
        }

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByType(type, startedAtSec, endedAtSec, limit)
        }

    fun listPostByTags(tags: List<String>, startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByTags(tags, startedAtSec, endedAtSec, limit)
        }

    fun listPostByLocations(
        locations: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao()
                .listOrderedPostByLocations(locations, startedAtSec, endedAtSec, limit)
        }

    fun savePosts(posts: List<PostR>) = databaseApi.rxSingle { databaseGateway ->
        val saveLocationStream = posts.filter { p -> p.location != null }.map { p ->
            p.location!!.applyCreatedAt(p.timestampSec)
            databaseGateway.locationDao().save(p.location!!)
        }
        if (saveLocationStream.isEmpty()) {
            Single.just(posts)
        } else {
            Completable.merge(saveLocationStream).andThen(Single.just(posts))
        }
    }.flatMap { ps ->
        databaseApi.rxSingle { databaseGateway ->
            ps.canonical()
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

    fun saveReactions(reactions: List<ReactionR>) = databaseApi.rxCompletable { databaseGateway ->
        databaseGateway.reactionDao().save(reactions)
    }

    fun listReaction(startedAtSec: Long, endedAtSec: Long, limit: Int = 20) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.reactionDao().listOrdered(startedAtSec, endedAtSec, limit)
        }

    fun listReactionByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long,
        limit: Int = 20
    ) = databaseApi.rxSingle { databaseGateway ->
        databaseGateway.reactionDao().listOrderedByType(reaction, startedAtSec, endedAtSec, limit)
    }

}