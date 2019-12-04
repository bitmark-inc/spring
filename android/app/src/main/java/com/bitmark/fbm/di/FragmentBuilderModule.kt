/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.di

import com.bitmark.fbm.feature.insights.InsightsContainerFragment
import com.bitmark.fbm.feature.insights.InsightsContainerModule
import com.bitmark.fbm.feature.offer.OfferContainerFragment
import com.bitmark.fbm.feature.offer.OfferContainerModule
import com.bitmark.fbm.feature.recovery.access.RecoveryAccessFragment
import com.bitmark.fbm.feature.recovery.access.RecoveryAccessModule
import com.bitmark.fbm.feature.recovery.notice.RecoveryNoticeFragment
import com.bitmark.fbm.feature.recovery.notice.RecoveryNoticeModule
import com.bitmark.fbm.feature.register.archiverequest.archiverequest.ArchiveRequestFragment
import com.bitmark.fbm.feature.register.archiverequest.archiverequest.ArchiveRequestModule
import com.bitmark.fbm.feature.register.archiverequest.credential.ArchiveRequestCredentialFragment
import com.bitmark.fbm.feature.register.archiverequest.credential.ArchiveRequestCredentialModule
import com.bitmark.fbm.feature.statistic.StatisticFragment
import com.bitmark.fbm.feature.statistic.StatisticModule
import com.bitmark.fbm.feature.unlink.notice.UnlinkNoticeFragment
import com.bitmark.fbm.feature.unlink.notice.UnlinkNoticeModule
import com.bitmark.fbm.feature.unlink.unlink.UnlinkFragment
import com.bitmark.fbm.feature.unlink.unlink.UnlinkModule
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.feature.usage.UsageContainerModule
import dagger.Module
import dagger.android.ContributesAndroidInjector

@Module
abstract class FragmentBuilderModule {

    @ContributesAndroidInjector(modules = [UsageContainerModule::class])
    @FragmentScope
    internal abstract fun bindUsageContainerFragment(): UsageContainerFragment

    @ContributesAndroidInjector(modules = [InsightsContainerModule::class])
    @FragmentScope
    internal abstract fun bindInsightsContainerFragment(): InsightsContainerFragment

    @ContributesAndroidInjector(modules = [OfferContainerModule::class])
    @FragmentScope
    internal abstract fun bindOfferContainerFragment(): OfferContainerFragment

    @ContributesAndroidInjector(modules = [UnlinkNoticeModule::class])
    @FragmentScope
    internal abstract fun bindUnlinkNoticeFragment(): UnlinkNoticeFragment

    @ContributesAndroidInjector(modules = [UnlinkModule::class])
    @FragmentScope
    internal abstract fun bindUnlinkFragment(): UnlinkFragment

    @ContributesAndroidInjector(modules = [RecoveryAccessModule::class])
    @FragmentScope
    internal abstract fun bindRecoveryAccessFragment(): RecoveryAccessFragment

    @ContributesAndroidInjector(modules = [RecoveryNoticeModule::class])
    @FragmentScope
    internal abstract fun bindRecoveryNoticeFragment(): RecoveryNoticeFragment

    @ContributesAndroidInjector(modules = [ArchiveRequestModule::class])
    @FragmentScope
    internal abstract fun bindArchiveRequestFragment(): ArchiveRequestFragment

    @ContributesAndroidInjector(modules = [ArchiveRequestCredentialModule::class])
    @FragmentScope
    internal abstract fun bindArchiveRequestCredentialFragment(): ArchiveRequestCredentialFragment

    @ContributesAndroidInjector(modules = [StatisticModule::class])
    @FragmentScope
    internal abstract fun bindStatisticFragment(): StatisticFragment
}