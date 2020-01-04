/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api

import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.source.remote.api.event.RemoteApiBus
import com.bitmark.fbm.data.source.remote.api.middleware.FbmApiInterceptor
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import com.bitmark.fbm.data.source.remote.api.service.ServiceGenerator
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

@Module
class NetworkModule {

    @Singleton
    @Provides
    fun provideFbmServerApi(
        apiInterceptor: FbmApiInterceptor
    ): FbmApi {
        return ServiceGenerator.createService(
            BuildConfig.FBM_API_ENDPOINT,
            FbmApi::class.java,
            newGsonInstance(),
            appInterceptors = listOf(apiInterceptor)
        )
    }

    @Singleton
    @Provides
    fun provideFbmInterceptor() = FbmApiInterceptor()

    @Singleton
    @Provides
    fun provideRemoteBus(apiInterceptor: FbmApiInterceptor) = RemoteApiBus(apiInterceptor)
}