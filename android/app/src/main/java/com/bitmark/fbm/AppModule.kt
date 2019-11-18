/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm

import android.app.Application
import android.content.Context
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.SentryEventLogger
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

@Module
class AppModule {

    @Provides
    @Singleton
    fun provideContext(application: Application): Context = application

    @Provides
    @Singleton
    fun provideAppLifecycleHandler() = AppLifecycleHandler()

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder().excludeFieldsWithoutExposeAnnotation().setLenient().create()
    }

    @Provides
    @Singleton
    fun provideEventLogger(accountRepo: AccountRepository): EventLogger =
        SentryEventLogger(accountRepo)

}