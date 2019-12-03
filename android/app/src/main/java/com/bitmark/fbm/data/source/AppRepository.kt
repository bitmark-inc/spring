/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.source.local.AppLocalDataSource
import com.bitmark.fbm.data.source.remote.AppRemoteDataSource


class AppRepository(
    private val remoteDataSource: AppRemoteDataSource,
    private val localDataSource: AppLocalDataSource
) {

    fun registerNotificationService(tags: Map<String, String>) =
        remoteDataSource.registerNotificationService(tags)

    fun setNotificationEnabled(enabled: Boolean) = localDataSource.setNotificationEnabled(enabled)

    fun checkNotificationEnabled() = localDataSource.checkNotificationEnabled()

    fun checkDataReady() = localDataSource.checkDataReady()

    fun getAutomationScript() = remoteDataSource.getAutomationScript()
}