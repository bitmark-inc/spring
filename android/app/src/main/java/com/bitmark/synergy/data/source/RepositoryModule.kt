/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.source

import android.content.Context
import androidx.room.Room
import com.bitmark.synergy.data.source.local.AccountLocalDataSource
import com.bitmark.synergy.data.source.local.api.DatabaseGateway
import com.bitmark.synergy.data.source.remote.AccountRemoteDataSource
import com.bitmark.synergy.data.source.remote.BitmarkRemoteDataSource
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
    fun provideBitmarkRepo(
        remoteDataSource: BitmarkRemoteDataSource
    ): BitmarkRepository {
        return BitmarkRepository(remoteDataSource)
    }

    @Singleton
    @Provides
    fun provideDatabaseGateway(context: Context): DatabaseGateway {
        return Room.databaseBuilder(
            context, DatabaseGateway::class.java,
            DatabaseGateway.DATABASE_NAME
        ).build()
    }

}