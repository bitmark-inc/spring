/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy

import android.app.Application
import com.bitmark.synergy.data.source.RepositoryModule
import com.bitmark.synergy.data.source.remote.api.NetworkModule
import com.bitmark.synergy.di.ActivityBuilderModule
import com.bitmark.synergy.di.FragmentBuilderModule
import dagger.BindsInstance
import dagger.Component
import dagger.android.AndroidInjector
import dagger.android.support.AndroidSupportInjectionModule
import javax.inject.Singleton

@Component(
    modules = [AndroidSupportInjectionModule::class, AppModule::class,
        ActivityBuilderModule::class, FragmentBuilderModule::class,
        NetworkModule::class, RepositoryModule::class]
)
@Singleton
interface AppComponent : AndroidInjector<SynergyApplication> {
    @Component.Builder
    interface Builder {

        @BindsInstance
        fun application(app: Application): Builder

        fun build(): AppComponent

    }
}