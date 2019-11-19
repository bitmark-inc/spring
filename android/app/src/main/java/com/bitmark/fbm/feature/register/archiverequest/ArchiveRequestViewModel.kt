/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Single

class ArchiveRequestViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val registerAccountLiveData = CompositeLiveData<Any>()

    fun registerAccount(
        requester: String,
        timestamp: String,
        signature: String,
        fbId: String,
        fbPassword: String,
        alias: String
    ) {
        registerAccountLiveData.add(
            rxLiveDataTransformer.completable(
                registerAccountStream(requester, timestamp, signature, fbId, fbPassword, alias)
            )
        )
    }

    private fun registerAccountStream(
        requester: String,
        timestamp: String,
        signature: String,
        fbId: String,
        fbPassword: String,
        alias: String
    ) = accountRepo.registerFbmServerAccount(
        timestamp,
        signature,
        requester
    ).flatMap { accountId ->
        accountRepo.sendArchiveDownloadRequest(accountId, fbId, fbPassword)
            .andThen(Single.just(accountId))
    }.flatMapCompletable { accountId ->
        accountRepo.saveAccountData(
            accountId,
            false,
            alias
        )
    }
}