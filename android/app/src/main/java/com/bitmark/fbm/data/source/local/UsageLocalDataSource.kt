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

    fun listPostByType(type: PostType, fromSec: Long, toSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByType(type, fromSec, toSec)
        }

    fun listPostByTag(tag: String, fromSec: Long, toSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByTag(tag, fromSec, toSec)
        }

    fun listPostByLocation(location: String, fromSec: Long, toSec: Long) =
        databaseApi.rxSingle { databaseGateway ->
            databaseGateway.postDao().listOrderedPostByLocation(location, fromSec, toSec)
        }

    fun savePosts(posts: List<PostR>) = databaseApi.rxSingle { databaseGateway ->
        val saveLocationStream = posts.filter { p -> p.location != null }.map { p ->
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

}