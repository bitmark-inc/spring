/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.di

import com.bitmark.fbm.feature.splash.SplashActivity
import com.bitmark.fbm.feature.splash.SplashModule
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestActivity
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestModule
import com.bitmark.fbm.feature.register.notification.RegisterNotificationActivity
import com.bitmark.fbm.feature.register.notification.RegisterNotificationModule
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingModule
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

    @ContributesAndroidInjector(modules = [SplashModule::class])
    @ActivityScope
    internal abstract fun bindGetStartedActivity(): SplashActivity

    @ContributesAndroidInjector(modules = [RegisterNotificationModule::class])
    @ActivityScope
    internal abstract fun bindRegisterNotificationActivity(): RegisterNotificationActivity
}