/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.notification

import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class NotificationModule {

    @ActivityScope
    @Provides
    fun provideNavigator(activity: NotificationActivity) = Navigator(activity)

    @ActivityScope
    @Provides
    fun provideVM(
        activity: NotificationActivity,
        appRepo: AppRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = NotificationViewModel(activity.lifecycle, appRepo, rxLiveDataTransformer)
}