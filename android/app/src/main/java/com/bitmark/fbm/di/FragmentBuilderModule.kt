/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.di

import com.bitmark.fbm.feature.account.AccountContainerFragment
import com.bitmark.fbm.feature.account.AccountContainerModule
import com.bitmark.fbm.feature.insights.InsightsContainerFragment
import com.bitmark.fbm.feature.insights.InsightsContainerModule
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.feature.usage.UsageContainerModule
import dagger.Module
import dagger.android.ContributesAndroidInjector

@Module
abstract class FragmentBuilderModule {

    @ContributesAndroidInjector(modules = [AccountContainerModule::class])
    @FragmentScope
    internal abstract fun bindAccountContainerFragment(): AccountContainerFragment

    @ContributesAndroidInjector(modules = [UsageContainerModule::class])
    @FragmentScope
    internal abstract fun bindUsageContainerFragment(): UsageContainerFragment

    @ContributesAndroidInjector(modules = [InsightsContainerModule::class])
    @FragmentScope
    internal abstract fun bindInsightsContainerFragment(): InsightsContainerFragment

}