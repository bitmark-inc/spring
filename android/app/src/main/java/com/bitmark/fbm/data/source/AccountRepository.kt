/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.source.local.AccountLocalDataSource
import com.bitmark.fbm.data.source.remote.AccountRemoteDataSource


class AccountRepository(
    private val remoteDataSource: AccountRemoteDataSource,
    private val localDataSource: AccountLocalDataSource
) {

    fun sendArchiveDownloadRequest(
        accountId: String,
        fbId: String,
        fbPassword: String
    ) = remoteDataSource.sendArchiveDownloadRequest(accountId, fbId, fbPassword)

    fun registerFbmServerAccount(
        timestamp: String,
        signature: String,
        requester: String
    ) = remoteDataSource.registerFbmServerJwt(
        timestamp,
        signature,
        requester
    ).andThen(remoteDataSource.registerFbmServerAccount())

    fun registerFbmServerJwt(
        timestamp: String,
        signature: String,
        requester: String
    ) = remoteDataSource.registerFbmServerJwt(
        timestamp,
        signature,
        requester
    )

    fun checkJwtExpired() = localDataSource.checkJwtExpired()

    fun saveAccountInfo(accountId: String, authRequired: Boolean, keyAlias: String) =
        localDataSource.saveAccountData(accountId, authRequired, keyAlias)

    fun getAccountInfo() = localDataSource.getAccountData()
}