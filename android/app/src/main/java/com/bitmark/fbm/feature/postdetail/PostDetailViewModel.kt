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

    fun listPost(startedAtSec: Long, endedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostStream(startedAtSec, endedAtSec, gapSec)
            )
        )
    }

    fun listNextPost(startedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostStream(startedAtSec, lastEndedAtSec - 1, gapSec)
            )
        )
    }

    private fun listPostStream(startedAtSec: Long, endedAtSec: Long, gapSec: Long) =
        usageRepo.listPost(
            startedAtSec,
            endedAtSec,
            gapSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByType(type: PostType, startedAtSec: Long, endedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTypeStream(type, startedAtSec, endedAtSec, gapSec)
            )
        )
    }

    fun listNextPostByType(type: PostType, startedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTypeStream(type, startedAtSec, lastEndedAtSec - 1, gapSec)
            )
        )
    }

    private fun listPostByTypeStream(
        type: PostType,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long
    ) =
        usageRepo.listPostByType(
            type,
            startedAtSec,
            endedAtSec,
            gapSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByTags(tags: List<String>, startedAtSec: Long, endedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTagsStream(tags, startedAtSec, endedAtSec, gapSec)
            )
        )
    }

    fun listNextPostByTags(tags: List<String>, startedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByTagsStream(tags, startedAtSec, lastEndedAtSec - 1, gapSec)
            )
        )
    }

    private fun listPostByTagsStream(
        tags: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long
    ) =
        usageRepo.listPostByTags(
            tags,
            startedAtSec,
            endedAtSec,
            gapSec
        ).observeOn(Schedulers.computation()).map(mapPosts())

    fun listPostByLocations(
        locations: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long
    ) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByLocationsStream(locations, startedAtSec, endedAtSec, gapSec)
            )
        )
    }

    fun listNextPostByLocations(locations: List<String>, startedAtSec: Long, gapSec: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                listPostByLocationsStream(locations, startedAtSec, lastEndedAtSec - 1, gapSec)
            )
        )
    }

    private fun listPostByLocationsStream(
        locations: List<String>,
        startedAtSec: Long,
        endedAtSec: Long,
        gapSec: Long
    ) =
        usageRepo.listPostByLocationNames(
            locations,
            startedAtSec,
            endedAtSec,
            gapSec
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