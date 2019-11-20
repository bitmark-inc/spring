/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.account

import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.Navigator
import dagger.Module
import dagger.Provides

@Module
class AccountModule {

    @Provides
    @ActivityScope
    fun provideNavigator(activity: AccountActivity) = Navigator(activity)
}