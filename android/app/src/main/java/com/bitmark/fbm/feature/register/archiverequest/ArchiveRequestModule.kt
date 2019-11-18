/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest

import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class ArchiveRequestModule {

    @Provides
    @ActivityScope
    fun provideViewModel(
        activity: ArchiveRequestActivity,
        accountRepo: AccountRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) =
        ArchiveRequestViewModel(activity.lifecycle, accountRepo, rxLiveDataTransformer)

    @Provides
    @ActivityScope
    fun provideNavigator(activity: ArchiveRequestActivity) = Navigator(activity)

    @Provides
    @ActivityScope
    fun provideDialogController(activity: ArchiveRequestActivity) = DialogController(activity)
}