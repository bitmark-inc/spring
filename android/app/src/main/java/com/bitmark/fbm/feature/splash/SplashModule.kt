/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class SplashModule {

    @Provides
    @ActivityScope
    fun provideNavigator(activity: SplashActivity) = Navigator(activity)

    @Provides
    @ActivityScope
    fun provideViewModel(
        activity: SplashActivity,
        accountRepo: AccountRepository,
        appRepo: AppRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = SplashViewModel(
        activity.lifecycle,
        accountRepo,
        appRepo,
        rxLiveDataTransformer
    )

    @Provides
    @ActivityScope
    fun provideDialogController(activity: SplashActivity) = DialogController(activity)
}