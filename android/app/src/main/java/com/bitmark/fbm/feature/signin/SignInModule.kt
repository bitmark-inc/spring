/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.signin

import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.data.source.remote.api.event.RemoteApiBus
import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class SignInModule {

    @ActivityScope
    @Provides
    fun provideVM(
        accountRepo: AccountRepository,
        appRepo: AppRepository,
        activity: SignInActivity,
        rxLiveDataTransformer: RxLiveDataTransformer,
        remoteApiBus: RemoteApiBus
    ) = SignInViewModel(
        activity.lifecycle,
        accountRepo,
        appRepo,
        rxLiveDataTransformer,
        remoteApiBus
    )

    @ActivityScope
    @Provides
    fun provideNav(activity: SignInActivity) = Navigator(activity)

    @ActivityScope
    @Provides
    fun provideDialogController(activity: SignInActivity) = DialogController(activity)
}