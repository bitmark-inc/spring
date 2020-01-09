/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import android.content.Context
import androidx.room.Room
import com.bitmark.fbm.data.source.local.*
import com.bitmark.fbm.data.source.local.api.DatabaseGateway
import com.bitmark.fbm.data.source.remote.*
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

@Module
class RepositoryModule {

    @Singleton
    @Provides
    fun provideAccountRepo(
        remoteDataSource: AccountRemoteDataSource,
        localDataSource: AccountLocalDataSource
    ): AccountRepository {
        return AccountRepository(remoteDataSource, localDataSource)
    }

    @Singleton
    @Provides
    fun provideAppRepo(
        remoteDataSource: AppRemoteDataSource,
        localDataSource: AppLocalDataSource
    ) = AppRepository(remoteDataSource, localDataSource)

    @Singleton
    @Provides
    fun provideInsightsRepo(
        remoteDataSource: InsightsRemoteDataSource,
        localDataSource: InsightsLocalDataSource
    ) = InsightsRepository(remoteDataSource, localDataSource)

    @Singleton
    @Provides
    fun provideUsageRepo(
        remoteDataSource: UsageRemoteDataSource,
        localDataSource: UsageLocalDataSource
    ) = UsageRepository(remoteDataSource, localDataSource)

    @Singleton
    @Provides
    fun provideStatisticRepo(
        remoteDataSource: StatisticRemoteDataSource,
        localDataSource: StatisticLocalDataSource
    ) = StatisticRepository(remoteDataSource, localDataSource)

    @Singleton
    @Provides
    fun provideDatabaseGateway(context: Context): DatabaseGateway {
        return Room.databaseBuilder(
            context, DatabaseGateway::class.java,
            DatabaseGateway.DATABASE_NAME
        ).build()
    }

}