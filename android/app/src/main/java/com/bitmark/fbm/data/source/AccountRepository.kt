/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.isValid
import com.bitmark.fbm.data.source.local.AccountLocalDataSource
import com.bitmark.fbm.data.source.remote.AccountRemoteDataSource


class AccountRepository(
    private val remoteDataSource: AccountRemoteDataSource,
    private val localDataSource: AccountLocalDataSource
) {

    fun sendArchiveDownloadRequest(
        archiveUrl: String,
        cookie: String,
        startedAtSec: Long,
        endedAtSec: Long
    ) = remoteDataSource.sendArchiveDownloadRequest(archiveUrl, cookie, startedAtSec, endedAtSec)

    fun registerFbmServerAccount(
        timestamp: String,
        signature: String,
        requester: String,
        encPubKey: String
    ) = registerFbmServerJwt(
        timestamp,
        signature,
        requester
    ).andThen(remoteDataSource.registerFbmServerAccount(encPubKey))

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

    fun saveAccountData(accountData: AccountData) =
        localDataSource.saveAccountData(accountData)

    fun getAccountData() = localDataSource.getAccountData()

    fun registerIntercomUser(id: String) = remoteDataSource.registerIntercomUser(id)

    fun setArchiveRequestedAt(timestamp: Long) =
        localDataSource.setArchiveRequestedAt(timestamp)

    fun clearArchiveRequestedAt() = localDataSource.clearArchiveRequestedAt()

    fun getArchiveRequestedAt() = localDataSource.getArchiveRequestedAt()

    fun checkFbCredentialExisting() = localDataSource.checkFbCredentialExisting()

    fun checkInvalidArchives() = remoteDataSource.getArchives().map { archives ->
        archives.none { a -> a.isValid() }
    }
}