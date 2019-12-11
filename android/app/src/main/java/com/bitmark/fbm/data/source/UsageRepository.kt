/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource
import io.reactivex.Single


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun listPostByType(type: PostType, fromSec: Long, toSec: Long) =
        localDataSource.listPostByType(type, fromSec, toSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByType(type, fromSec, toSec).andThen(
                    localDataSource.listPostByType(
                        type,
                        fromSec,
                        toSec
                    )
                )
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByType(type: PostType, fromSec: Long, toSec: Long) =
        remoteDataSource.listPostByType(type, fromSec, toSec)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByTag(tag: String, fromSec: Long, toSec: Long) =
        localDataSource.listPostByTag(tag, fromSec, toSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByTag(tag, fromSec, toSec).andThen(
                    localDataSource.listPostByTag(
                        tag,
                        fromSec,
                        toSec
                    )
                )
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByTag(tag: String, fromSec: Long, toSec: Long) =
        remoteDataSource.listPostByTag(tag, fromSec, toSec)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

    fun listPostByLocation(location: String, fromSec: Long, toSec: Long) =
        localDataSource.listPostByLocation(location, fromSec, toSec).flatMap { posts ->
            if (posts.isEmpty()) {
                listRemotePostByLocation(
                    location,
                    fromSec,
                    toSec
                ).andThen(localDataSource.listPostByLocation(location, fromSec, toSec))
            } else {
                Single.just(posts)
            }
        }

    private fun listRemotePostByLocation(location: String, fromSec: Long, toSec: Long) =
        remoteDataSource.listPostByLocation(location, fromSec, toSec)
            .flatMapCompletable { p -> localDataSource.savePosts(p) }

}