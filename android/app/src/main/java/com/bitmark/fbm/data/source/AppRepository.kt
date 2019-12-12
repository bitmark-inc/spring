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
        remoteDataSource.getAppInfo().map { info -> BuildConfig.VERSION_CODE < info.androidAppInfo.requiredVersion }
}