/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import javax.inject.Inject


class AppLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun setNotificationEnabled(enabled: Boolean) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.NOTIFICATION_ENABLED, enabled)
        }

    fun checkNotificationEnabled() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(SharedPrefApi.NOTIFICATION_ENABLED, Boolean::class)
    }

    fun checkDataReady() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(SharedPrefApi.DATA_READY, Boolean::class)
    }

    fun setDataReady() = sharedPrefApi.rxCompletable { sharedPrefGateway ->
        sharedPrefGateway.put(SharedPrefApi.DATA_READY, true)
    }
}