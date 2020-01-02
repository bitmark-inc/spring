/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.auth.FbmServerAuthentication
import dagger.Module
import dagger.Provides


@Module
class MainModule {

    @Provides
    @ActivityScope
    fun provideNavigator(activity: MainActivity) = Navigator(activity)

    @Provides
    @ActivityScope
    fun provideVM(activity: MainActivity, fbmServerAuth: FbmServerAuthentication) =
        MainViewModel(activity.lifecycle, fbmServerAuth)
}