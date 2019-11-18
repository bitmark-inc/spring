/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.getstarted

import com.bitmark.fbm.di.ActivityScope
import com.bitmark.fbm.feature.Navigator
import dagger.Module
import dagger.Provides

@Module
class GetStartedModule {

    @Provides
    @ActivityScope
    fun provideNavigator(activity: GetStartedActivity) = Navigator(activity)
}