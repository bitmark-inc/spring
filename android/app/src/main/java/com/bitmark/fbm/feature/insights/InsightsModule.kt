/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.insights

import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.StatisticRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class InsightsModule {

    @Provides
    @FragmentScope
    fun provideNavigator(fragment: InsightsFragment) = Navigator(fragment.parentFragment!!)

    @Provides
    @FragmentScope
    fun provideViewModel(
        fragment: InsightsFragment,
        statisticRepo: StatisticRepository,
        accountRepo: AccountRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = InsightsViewModel(fragment.lifecycle, statisticRepo, accountRepo, rxLiveDataTransformer)

    @Provides
    @FragmentScope
    fun provideDialogController(fragment: InsightsFragment) = DialogController(fragment.activity!!)
}