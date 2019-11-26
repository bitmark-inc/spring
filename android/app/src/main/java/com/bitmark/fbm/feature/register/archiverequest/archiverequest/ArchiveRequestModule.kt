/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.archiverequest

import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import dagger.Module
import dagger.Provides

@Module
class ArchiveRequestModule {

    @Provides
    @FragmentScope
    fun provideNavigator(fragment: ArchiveRequestFragment) = Navigator(fragment)

    @Provides
    @FragmentScope
    fun provideViewModel(
        fragment: ArchiveRequestFragment,
        accountRepo: AccountRepository,
        appRepo: AppRepository,
        rxLiveDataTransformer: RxLiveDataTransformer
    ) = ArchiveRequestViewModel(fragment.lifecycle, accountRepo, appRepo, rxLiveDataTransformer)

    @Provides
    @FragmentScope
    fun provideDialogController(fragment: ArchiveRequestFragment) =
        DialogController(fragment.activity!!)

}