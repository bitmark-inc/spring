/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest

import androidx.lifecycle.Lifecycle
import com.bitmark.cryptography.crypto.Sha3256
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Completable
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
    ): Completable {
        return accountRepo.registerFbmServerAccount(
            timestamp,
            signature,
            requester
        ).flatMap { accountId ->
            val intercomId =
                "FBM_android_%s".format(Sha3256.hash(RAW.decode(requester)))
            Completable.mergeArray(
                accountRepo.registerIntercomUser(intercomId),
                accountRepo.sendArchiveDownloadRequest(accountId, fbId, fbPassword)
            ).andThen(Single.just(accountId))
        }.flatMapCompletable { accountId ->
            accountRepo.saveAccountData(
                accountId,
                false,
                alias
            )
        }
    }
}