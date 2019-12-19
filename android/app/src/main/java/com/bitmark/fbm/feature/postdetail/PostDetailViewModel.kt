/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.postdetail

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.PostModelView
import io.reactivex.schedulers.Schedulers


class PostDetailViewModel(
    lifecycle: Lifecycle,
    private val usageRepo: UsageRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val listPostLiveData = CompositeLiveData<List<PostModelView>>()

    private var lastEndedAtSec = -1L

    fun listPost(startedAtSec: Long, endedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostStream(startedAtSec, endedAtSec)
            )
        )
    }

    fun listNextPost(startedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostStream(startedAtSec, lastEndedAtSec - 1)
            )
        )
    }

    private fun listPostStream(startedAtSec: Long, endedAtSec: Long) =
        usageRepo.listPost(
            startedAtSec,
            endedAtSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTypeStream(type, startedAtSec, endedAtSec)
            )
        )
    }

    fun listNextPostByType(type: PostType, startedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTypeStream(type, startedAtSec, lastEndedAtSec - 1)
            )
        )
    }

    private fun listPostByTypeStream(type: PostType, startedAtSec: Long, endedAtSec: Long) =
        usageRepo.listPostByType(
            type,
            startedAtSec,
            endedAtSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByTag(tag: String, startedAtSec: Long, endedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTagStream(tag, startedAtSec, endedAtSec)
            )
        )
    }

    fun listNextPostByTag(tag: String, startedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTagStream(tag, startedAtSec, lastEndedAtSec - 1)
            )
        )
    }

    private fun listPostByTagStream(tag: String, startedAtSec: Long, endedAtSec: Long) =
        usageRepo.listPostByTag(
            tag,
            startedAtSec,
            endedAtSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByLocation(location: String, startedAtSec: Long, endedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByLocationStream(location, startedAtSec, endedAtSec)
            )
        )
    }

    fun listNextPostByLocation(location: String, startedAtSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByLocationStream(location, startedAtSec, lastEndedAtSec - 1)
            )
        )
    }

    fun listPostByLocationStream(location: String, startedAtSec: Long, endedAtSec: Long) =
        usageRepo.listPostByLocation(
            location,
            startedAtSec,
            endedAtSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    private fun mapPosts(): (List<PostData>) -> List<PostModelView> =
        { posts ->
            if (posts.isNotEmpty()) {
                lastEndedAtSec = posts.last().timestampSec
            }
            posts.filter { p -> p.type != PostType.UNSPECIFIED }
                .map { p -> PostModelView.newInstance(p) }
        }
}