/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.source.local.AppLocalDataSource
import com.bitmark.fbm.data.source.remote.AppRemoteDataSource
import io.reactivex.Completable


class AppRepository(
    private val remoteDataSource: AppRemoteDataSource,
    private val localDataSource: AppLocalDataSource
) {

    fun registerNotificationService(accountId: String) =
        remoteDataSource.registerNotificationService(accountId)

    fun setNotificationEnabled(enabled: Boolean) = localDataSource.setNotificationEnabled(enabled)

    fun checkNotificationEnabled() = localDataSource.checkNotificationEnabled()

    fun checkDataReady() = localDataSource.checkDataReady()

    fun setDataReady() = localDataSource.setDataReady()

    fun getAutomationScript() = remoteDataSource.getAutomationScript()

    fun checkVersionOutOfDate() =
        remoteDataSource.getAppInfo().map { info ->
            Pair(
                BuildConfig.VERSION_CODE < info.androidAppInfo.requiredVersion,
                info.androidAppInfo.updateUrl
            )
        }

    fun getUpdateAppUrl() =
        remoteDataSource.getAppInfo().map { info -> info.androidAppInfo.updateUrl }

    fun deleteAppData(keepAccountData: Boolean = false) = Completable.mergeArray(
        localDataSource.deleteDb(),
        localDataSource.deleteSharePref(keepAccountData),
        localDataSource.deleteFileStorage(keepAccountData)
    )
}