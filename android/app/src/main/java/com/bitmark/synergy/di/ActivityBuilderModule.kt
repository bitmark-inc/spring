/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.di

import com.bitmark.synergy.feature.getstarted.GetStartedActivity
import com.bitmark.synergy.feature.getstarted.GetStartedModule
import com.bitmark.synergy.feature.register.archiverequest.ArchiveRequestActivity
import com.bitmark.synergy.feature.register.archiverequest.ArchiveRequestModule
import com.bitmark.synergy.feature.register.notification.RegisterNotificationActivity
import com.bitmark.synergy.feature.register.notification.RegisterNotificationModule
import com.bitmark.synergy.feature.register.onboarding.OnboardingActivity
import com.bitmark.synergy.feature.register.onboarding.OnboardingModule
import dagger.Module
import dagger.android.ContributesAndroidInjector

@Module
abstract class ActivityBuilderModule {

    @ContributesAndroidInjector(modules = [OnboardingModule::class])
    @ActivityScope
    internal abstract fun bindOnBoardingActivity(): OnboardingActivity

    @ContributesAndroidInjector(modules = [ArchiveRequestModule::class])
    @ActivityScope
    internal abstract fun bindArchiveRequestActivity(): ArchiveRequestActivity

    @ContributesAndroidInjector(modules = [GetStartedModule::class])
    @ActivityScope
    internal abstract fun bindGetStartedActivity(): GetStartedActivity

    @ContributesAndroidInjector(modules = [RegisterNotificationModule::class])
    @ActivityScope
    internal abstract fun bindRegisterNotificationActivity(): RegisterNotificationActivity
}