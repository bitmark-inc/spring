/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usagedetail

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.PostData
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.PostModelView
import io.reactivex.schedulers.Schedulers


class UsageDetailViewModel(
    lifecycle: Lifecycle,
    private val usageRepo: UsageRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val listPostLiveData = CompositeLiveData<List<PostModelView>>()

    fun listPostByType(type: PostType, from: Long, to: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                usageRepo.listPostByType(
                    type,
                    from,
                    to
                ).observeOn(Schedulers.computation()).map(mapPosts())
            )
        )
    }

    fun listPostByTag(tag: String, from: Long, to: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                usageRepo.listPostByTag(
                    tag,
                    from,
                    to
                ).observeOn(Schedulers.computation()).map(mapPosts())
            )
        )
    }

    fun listPostByLocation(location: String, from: Long, to: Long) {
        listPostLiveData.add(
            rxLiveDataTransformer.single(
                usageRepo.listPostByLocation(
                    location,
                    from,
                    to
                ).observeOn(Schedulers.computation()).map(mapPosts())
            )
        )
    }

    private fun mapPosts(): (List<PostData>) -> List<PostModelView> =
        { posts ->
            posts.filter { p -> p.type != PostType.UNSPECIFIED }
                .map { p -> PostModelView.newInstance(p) }
        }
}