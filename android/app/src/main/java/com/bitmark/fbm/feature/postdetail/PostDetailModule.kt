/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.postdetail

import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class PostDetailModule {

    @Provides
    @FragmentScope
    fun provideNav(fragment: PostDetailFragment) = Navigator(fragment.parentFragment!!)

    @Provides
    @FragmentScope
    fun provideVM(
        fragment: PostDetailFragment,
        usageRepo: UsageRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = PostDetailViewModel(fragment.lifecycle, usageRepo, rxLiveDataTransformer)
}