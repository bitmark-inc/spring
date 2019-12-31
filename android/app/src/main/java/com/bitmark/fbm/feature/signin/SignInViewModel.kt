/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.signin

import androidx.lifecycle.Lifecycle
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.sdk.features.Account
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers


class SignInViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val prepareDataLiveData = CompositeLiveData<Any>()

    fun prepareData(account: Account, keyAlias: String, authRequired: Boolean) {
        prepareDataLiveData.add(
            rxLiveDataTransformer.completable(
                prepareDataStream(
                    account,
                    keyAlias,
                    authRequired
                )
            )
        )
    }

    private fun prepareDataStream(account: Account, keyAlias: String, authRequired: Boolean) =
        Single.fromCallable {
            val requester = account.accountNumber
            val timestamp = System.currentTimeMillis().toString()
            val signature = HEX.encode(account.sign(RAW.decode(timestamp)))
            Triple(requester, timestamp, signature)
        }.subscribeOn(Schedulers.computation()).observeOn(Schedulers.io()).flatMapCompletable { t ->
            val requester = t.first
            val timestamp = t.second
            val signature = t.third
            accountRepo.registerFbmServerJwt(timestamp, signature, requester)
        }.andThen(accountRepo.syncAccountData().flatMapCompletable { accountData ->
            accountData.keyAlias = keyAlias
            accountData.authRequired = authRequired
            Completable.mergeArray(
                accountRepo.saveAccountData(accountData),
                appRepo.registerNotificationService(accountData.id)
            )
        })
}