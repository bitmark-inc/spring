/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.archiverequest

import com.bitmark.synergy.di.ActivityScope
import com.bitmark.synergy.feature.Navigator
import dagger.Module
import dagger.Provides

@Module
class ArchiveRequestModule {

    @Provides
    @ActivityScope
    fun provideViewModel(activity: ArchiveRequestActivity) =
        ArchiveRequestViewModel(activity.lifecycle)

    @Provides
    @ActivityScope
    fun provideNavigator(activity: ArchiveRequestActivity) = Navigator(activity)

}