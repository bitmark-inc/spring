/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import com.bitmark.fbm.data.source.StatisticRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class StatisticModule {

    @Provides
    @FragmentScope
    fun provideViewModel(
        fragment: StatisticFragment,
        statisticRepo: StatisticRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = StatisticViewModel(fragment.lifecycle, statisticRepo, rxLiveDataTransformer)

    @Provides
    @FragmentScope
    fun provideNavigator(fragment: StatisticFragment) =
        Navigator(fragment.parentFragment?.parentFragment!!)

    @Provides
    @FragmentScope
    fun provideDialogController(fragment: StatisticFragment) = DialogController(fragment.activity!!)

}