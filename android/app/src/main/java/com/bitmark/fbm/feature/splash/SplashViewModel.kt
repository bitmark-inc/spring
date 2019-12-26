/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import androidx.lifecycle.Lifecycle
import com.bitmark.cryptography.crypto.encoder.Hex
import com.bitmark.cryptography.crypto.encoder.Raw
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.data.source.remote.api.error.NetworkException
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.sdk.features.Account
import io.reactivex.Single
import io.reactivex.functions.BiFunction
import io.reactivex.schedulers.Schedulers


class SplashViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val getAccountInfoLiveData = CompositeLiveData<Pair<AccountData, Long>>()

    internal val checkVersionOutOfDateLiveData = CompositeLiveData<Pair<Boolean, String>>()

    // annotate that data has been deleted or not
    internal val prepareDataLiveData = CompositeLiveData<Boolean>()

    internal val checkDataReadyLiveData = CompositeLiveData<Boolean>()

    fun getAccountInfo() {
        getAccountInfoLiveData.add(
            rxLiveDataTransformer.single(
                Single.zip(
                    accountRepo.getAccountData(),
                    accountRepo.getArchiveRequestedAt(),
                    BiFunction<AccountData, Long, Pair<AccountData, Long>> { account, archiveRequested ->
                        Pair(
                            account,
                            archiveRequested
                        )
                    })
            )
        )
    }

    fun checkVersionOutOfDate() {
        checkVersionOutOfDateLiveData.add(rxLiveDataTransformer.single(appRepo.checkVersionOutOfDate()))
    }

    fun prepareData(account: Account) {
        prepareDataLiveData.add(
            rxLiveDataTransformer.single(
                registerJwtStream(account).andThen(
                    checkInvalidArchiveStream()
                ).onErrorResumeNext { e ->
                    if (e is NetworkException) {
                        Single.just(false)
                    } else {
                        Single.error<Boolean>(e)
                    }
                }.flatMap { invalid ->
                    if (invalid) {
                        // keep account data for next time using
                        appRepo.deleteAppData(true).andThen(Single.just(true))
                    } else {
                        Single.just(false)
                    }
                })
        )
    }

    private fun checkInvalidArchiveStream() = Single.zip(
        accountRepo.getArchiveRequestedAt(),
        accountRepo.checkInvalidArchives(),
        BiFunction<Long, Boolean, Boolean> { archiveRequestedAt, invalidArchives ->
            val stillRequested = archiveRequestedAt != -1L
            !stillRequested && invalidArchives
        })


    private fun registerJwtStream(account: Account) = Single.fromCallable {
        val requester = account.accountNumber
        val timestamp = System.currentTimeMillis().toString()
        val signature = Hex.HEX.encode(account.sign(Raw.RAW.decode(timestamp)))
        Triple(timestamp, signature, requester)
    }.subscribeOn(Schedulers.computation()).observeOn(Schedulers.io())
        .flatMapCompletable { t ->
            accountRepo.registerFbmServerJwt(t.first, t.second, t.third)
        }

    fun checkDataReady() {
        checkDataReadyLiveData.add(rxLiveDataTransformer.single(appRepo.checkDataReady().flatMap { ready ->
            if (ready) {
                Single.just(ready)
            } else {
                accountRepo.checkArchiveProcessed().flatMap { processed ->
                    if (processed) {
                        appRepo.setDataReady().andThen(Single.just(true))
                    } else {
                        Single.just(false)
                    }
                }
            }
        }))
    }

}