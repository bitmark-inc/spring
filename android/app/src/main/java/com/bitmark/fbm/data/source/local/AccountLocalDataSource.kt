/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local

import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.CredentialData
import com.bitmark.fbm.data.source.local.api.DatabaseApi
import com.bitmark.fbm.data.source.local.api.FileStorageApi
import com.bitmark.fbm.data.source.local.api.SharedPrefApi
import io.reactivex.Single
import java.util.concurrent.TimeUnit
import javax.inject.Inject


class AccountLocalDataSource @Inject constructor(
    databaseApi: DatabaseApi,
    sharedPrefApi: SharedPrefApi,
    fileStorageApi: FileStorageApi
) : LocalDataSource(databaseApi, sharedPrefApi, fileStorageApi) {

    fun checkJwtExpired() = Single.fromCallable {
        System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(5) > Jwt.getInstance().expiredAt
    }

    fun saveAccountData(accountData: AccountData) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.ACCOUNT_DATA, newGsonInstance().toJson(accountData))
        }

    fun getAccountData(): Single<AccountData> = sharedPrefApi.rxSingle { sharedPrefGateway ->
        val accountData = newGsonInstance().fromJson(
            sharedPrefGateway.get(SharedPrefApi.ACCOUNT_DATA, String::class),
            AccountData::class.java
        )
        accountData ?: AccountData.newEmptyInstance()
    }

    fun clearArchiveRequestedAt() = sharedPrefApi.rxCompletable { sharedPrefGateway ->
        sharedPrefGateway.clear(SharedPrefApi.ARCHIVE_REQUESTED_TIME)
    }

    fun setArchiveRequestedAt(timestamp: Long) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(SharedPrefApi.ARCHIVE_REQUESTED_TIME, timestamp)
        }

    fun getArchiveRequestedAt() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(SharedPrefApi.ARCHIVE_REQUESTED_TIME, Long::class, -1L)
    }

    fun checkFbCredentialExisting() = fileStorageApi.rxSingle { fileStorageGateway ->
        fileStorageGateway.isExistingOnFilesDir(CredentialData.CREDENTIAL_FILE_NAME)
    }

    fun saveAccountKeyAlias(alias: String, authRequired: Boolean) =
        getAccountData().flatMapCompletable { accountData ->
            accountData.keyAlias = alias
            accountData.authRequired = authRequired
            saveAccountData(accountData)
        }

    fun saveAdsPrefCategories(categories: List<String>) =
        sharedPrefApi.rxCompletable { sharedPrefGateway ->
            sharedPrefGateway.put(
                SharedPrefApi.FB_ADS_PREF_CATEGORIES,
                newGsonInstance().toJson(categories)
            )
        }

    fun listAdsPrefCategory() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        newGsonInstance().fromJson<List<String>>(
            sharedPrefGateway.get(
                SharedPrefApi.FB_ADS_PREF_CATEGORIES,
                String::class
            )
        )
    }

    fun checkAdsPrefCategoryReady() = sharedPrefApi.rxSingle { sharedPrefGateway ->
        sharedPrefGateway.get(
            SharedPrefApi.FB_ADS_PREF_CATEGORIES,
            String::class
        ) != ""
    }

}