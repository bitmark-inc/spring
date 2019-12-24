/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.locationdetail

import com.bitmark.fbm.data.source.InsightsRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class LocationDetailModule {

    @FragmentScope
    @Provides
    fun provideNav(fragment: LocationDetailFragment) = Navigator(fragment.parentFragment!!)

    @FragmentScope
    @Provides
    fun provideVM(
        fragment: LocationDetailFragment,
        insightsRepo: InsightsRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = LocationDetailViewModel(fragment.lifecycle, insightsRepo, rxLiveDataTransformer)

}