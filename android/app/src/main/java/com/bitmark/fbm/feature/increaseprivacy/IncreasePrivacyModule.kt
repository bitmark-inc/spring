/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.increaseprivacy

import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class IncreasePrivacyModule {

    @ActivityScope
    @Provides
    fun provideVM(
        activity: IncreasePrivacyActivity,
        appRepo: AppRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = IncreasePrivacyViewModel(activity.lifecycle, appRepo, rxLiveDataTransformer)

    @ActivityScope
    @Provides
    fun provideNav(activity: IncreasePrivacyActivity) = Navigator(activity)
}