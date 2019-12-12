/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import com.google.gson.Gson
import io.reactivex.Single
import javax.inject.Inject


class AccountLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi,
    private val gson: Gson
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun checkJwtExpired() = Single.fromCallable {
        System.currentTimeMillis() - Jwt.getInstance().expiredAt <= 0
    }

    fun saveAccountData(accountData: AccountData) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.ACCOUNT_DATA, gson.toJson(accountData))
        }

    fun getAccountData(): Single<AccountData> = sharedPrefApi.rxSingle { sharedPrefGateway ->
        val accountData = gson.fromJson(
            sharedPrefGateway.get(SharedPrefApi.ACCOUNT_DATA, String::class),
            AccountData::class.java
        )
        accountData ?: throw IllegalAccessException("account not found")
    }

    fun setArchiveRequestedTimestamp(timestamp: Long) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.ARCHIVE_REQUESTED_TIME, timestamp)
        }

    fun getArchiveRequestedTimestamp() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(SharedPrefApi.ARCHIVE_REQUESTED_TIME, Long::class, -1L)
    }

    fun checkArchiveRequested() = getArchiveRequestedTimestamp().map { t -> t != -1L }

    fun saveFbCredentialAlias(alias: String) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.FB_CREDENTIAL_ALIAS, alias)
        }

    fun getFbCredentialAlias() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(SharedPrefApi.FB_CREDENTIAL_ALIAS, String::class)
    }
}