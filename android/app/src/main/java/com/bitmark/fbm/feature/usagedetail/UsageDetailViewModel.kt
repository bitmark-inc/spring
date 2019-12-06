/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usagedetail

import androidx.lifecycle.Lifecycle
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

    internal val getPostLiveData = CompositeLiveData<List<PostModelView>>()

    fun getPost(type: PostType, from: Long, to: Long) {
        getPostLiveData.add(
            rxLiveDataTransformer.single(
                usageRepo.getPost(
                    type,
                    from,
                    to
                ).map { posts -> posts.map { p -> PostModelView.newInstance(p) } })
        )
    }
}