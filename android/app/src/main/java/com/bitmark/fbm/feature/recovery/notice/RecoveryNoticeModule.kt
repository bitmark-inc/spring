/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.recovery.notice

import com.bitmark.fbm.di.FragmentScope
import com.bitmark.fbm.feature.Navigator
import dagger.Module
import dagger.Provides

@Module
class RecoveryNoticeModule {

    @Provides
    @FragmentScope
    fun provideNavigator(fragment: RecoveryNoticeFragment) = Navigator(fragment)

    @Provides
    @FragmentScope
    fun provideViewModel(fragment: RecoveryNoticeFragment) =
        RecoveryNoticeViewModel(fragment.lifecycle)
}