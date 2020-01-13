/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.di

import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.feature.account.AccountModule
import com.bitmark.fbm.feature.biometricauth.BiometricAuthActivity
import com.bitmark.fbm.feature.biometricauth.BiometricAuthModule
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.main.MainModule
import com.bitmark.fbm.feature.recovery.RecoveryContainerActivity
import com.bitmark.fbm.feature.recovery.RecoveryContainerModule
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerModule
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingActivity
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingModule
import com.bitmark.fbm.feature.register.notification.NotificationActivity
import com.bitmark.fbm.feature.register.notification.NotificationModule
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingModule
import com.bitmark.fbm.feature.register.trustnotice.TrustNoticeActivity
import com.bitmark.fbm.feature.register.trustnotice.TrustNoticeModule
import com.bitmark.fbm.feature.signin.SignInActivity
import com.bitmark.fbm.feature.signin.SignInModule
import com.bitmark.fbm.feature.splash.SplashActivity
import com.bitmark.fbm.feature.splash.SplashModule
import com.bitmark.fbm.feature.support.SupportActivity
import com.bitmark.fbm.feature.support.SupportModule
import com.bitmark.fbm.feature.unlink.UnlinkContainerActivity
import com.bitmark.fbm.feature.unlink.UnlinkContainerModule
import com.bitmark.fbm.feature.whatsnew.WhatsNewActivity
import com.bitmark.fbm.feature.whatsnew.WhatsNewModule
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

    @ContributesAndroidInjector(modules = [DataProcessingModule::class])
    @ActivityScope
    internal abstract fun bindDataProcessingActivity(): DataProcessingActivity

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

    @ContributesAndroidInjector(modules = [NotificationModule::class])
    @ActivityScope
    internal abstract fun bindNotificationActivity(): NotificationActivity

    @ContributesAndroidInjector(modules = [TrustNoticeModule::class])
    @ActivityScope
    internal abstract fun bindTrustNoticeActivity(): TrustNoticeActivity

    @ContributesAndroidInjector(modules = [SignInModule::class])
    @ActivityScope
    internal abstract fun bindSignInActivity(): SignInActivity

    @ContributesAndroidInjector(modules = [WhatsNewModule::class])
    @ActivityScope
    internal abstract fun bindWhatsNewActivity(): WhatsNewActivity
}