/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usagedetail

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.entity.PostR
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.PostModelView


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
                ).map(mapPosts())
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
                ).map(mapPosts())
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
                ).map(mapPosts())
            )
        )
    }

    private fun mapPosts(): (List<PostR>) -> List<PostModelView> =
        { posts -> posts.map { p -> PostModelView.newInstance(p) } }
}