/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.di

import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.feature.account.AccountModule
import com.bitmark.fbm.feature.auth.BiometricAuthActivity
import com.bitmark.fbm.feature.auth.BiometricAuthModule
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.main.MainModule
import com.bitmark.fbm.feature.recovery.RecoveryContainerActivity
import com.bitmark.fbm.feature.recovery.RecoveryContainerModule
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerModule
import com.bitmark.fbm.feature.register.notification.RegisterNotificationActivity
import com.bitmark.fbm.feature.register.notification.RegisterNotificationModule
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingModule
import com.bitmark.fbm.feature.splash.SplashActivity
import com.bitmark.fbm.feature.splash.SplashModule
import com.bitmark.fbm.feature.support.SupportActivity
import com.bitmark.fbm.feature.support.SupportModule
import com.bitmark.fbm.feature.unlink.UnlinkContainerActivity
import com.bitmark.fbm.feature.unlink.UnlinkContainerModule
import dagger.Module
import dagger.android.ContributesAndroidInjector

@Module
abstract class ActivityBuilderModule {

    @ContributesAndroidInjector(modules = [OnboardingModule::class])
    @ActivityScope
    internal abstract fun bindOnBoardingActivity(): OnboardingActivity

    @ContributesAndroidInjector(modules = [ArchiveRequestContainerModule::class])
    @ActivityScope
    internal abstract fun bindArchiveRequestContainerActivity(): ArchiveRequestContainerActivity

    @ContributesAndroidInjector(modules = [SplashModule::class])
    @ActivityScope
    internal abstract fun bindGetStartedActivity(): SplashActivity

    @ContributesAndroidInjector(modules = [RegisterNotificationModule::class])
    @ActivityScope
    internal abstract fun bindRegisterNotificationActivity(): RegisterNotificationActivity

    @ContributesAndroidInjector(modules = [MainModule::class])
    @ActivityScope
    internal abstract fun bindMainActivity(): MainActivity

    @ContributesAndroidInjector(modules = [AccountModule::class])
    @ActivityScope
    internal abstract fun bindAccountActivity(): AccountActivity

    @ContributesAndroidInjector(modules = [UnlinkContainerModule::class])
    @ActivityScope
    internal abstract fun bindUnlinkContainerActivity(): UnlinkContainerActivity

    @ContributesAndroidInjector(modules = [BiometricAuthModule::class])
    @ActivityScope
    internal abstract fun bindBiometricAuthActivity(): BiometricAuthActivity

    @ContributesAndroidInjector(modules = [RecoveryContainerModule::class])
    @ActivityScope
    internal abstract fun bindRecoveryContainerActivity(): RecoveryContainerActivity

    @ContributesAndroidInjector(modules = [SupportModule::class])
    @ActivityScope
    internal abstract fun bindSupportActivity(): SupportActivity
}