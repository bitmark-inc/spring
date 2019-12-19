/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.reactiondetail

import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class ReactionDetailModule {

    @Provides
    @FragmentScope
    fun provideNav(fragment: ReactionDetailFragment) = Navigator(fragment.parentFragment!!)

    @Provides
    @FragmentScope
    fun provideVM(
        fragment: ReactionDetailFragment,
        usageRepo: UsageRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = ReactionDetailViewModel(fragment.lifecycle, usageRepo, rxLiveDataTransformer)
}