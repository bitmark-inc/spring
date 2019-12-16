/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.archiverequest

import androidx.lifecycle.Lifecycle
import com.bitmark.cryptography.crypto.Sha3256
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.AutomationScriptData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.sdk.features.Account
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.functions.BiFunction
import io.reactivex.schedulers.Schedulers

class ArchiveRequestViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val registerAccountLiveData = CompositeLiveData<Any>()

    internal val prepareDataLiveData = CompositeLiveData<Pair<AutomationScriptData, Boolean>>()

    internal val checkNotificationEnabledLiveData = CompositeLiveData<Boolean>()

    internal val saveArchiveRequestedAtLiveData = CompositeLiveData<Any>()

    internal val getExistingAccountDataLiveData = CompositeLiveData<AccountData>()

    fun registerAccount(
        account: Account,
        archiveUrl: String,
        cookie: String,
        alias: String,
        registered: Boolean
    ) {
        registerAccountLiveData.add(
            rxLiveDataTransformer.completable(
                registerAccountStream(
                    account,
                    archiveUrl,
                    cookie,
                    alias,
                    registered
                )
            )
        )
    }

    private fun registerAccountStream(
        account: Account,
        archiveUrl: String,
        cookie: String,
        alias: String,
        registered: Boolean
    ): Completable {

        val registerAccountStream = Single.fromCallable {
            val requester = account.accountNumber
            val timestamp = System.currentTimeMillis().toString()
            val signature = HEX.encode(account.sign(RAW.decode(timestamp)))
            Triple(requester, timestamp, signature)
        }.subscribeOn(Schedulers.computation()).observeOn(Schedulers.io())
            .flatMap { t ->
                val requester = t.first
                val timestamp = t.second
                val signature = t.third
                if (registered) {
                    accountRepo.registerFbmServerJwt(timestamp, signature, requester)
                        .andThen(accountRepo.getAccountData())
                } else {
                    accountRepo.registerFbmServerAccount(
                        timestamp,
                        signature,
                        requester
                    )
                }
            }


        return Single.zip(registerAccountStream,
            accountRepo.getArchiveRequestedAt(),
            BiFunction<AccountData, Long, Pair<AccountData, Long>> { accountData, archiveRequestedAt ->
                Pair(
                    accountData,
                    archiveRequestedAt
                )
            })
            .flatMap { p ->
                val accountData = p.first
                val archiveRequestedAt = p.second
                val intercomId =
                    "FBM_android_%s".format(Sha3256.hash(RAW.decode(accountData.id)))
                Completable.mergeArray(
                    accountRepo.registerIntercomUser(intercomId),
                    accountRepo.sendArchiveDownloadRequest(
                        archiveUrl,
                        cookie,
                        0L,
                        archiveRequestedAt / 1000
                    ),
                    appRepo.registerNotificationService(accountData.id)
                ).andThen(Single.just(accountData))
            }.flatMapCompletable { accountData ->
                accountData.authRequired = false
                accountData.keyAlias = alias
                Completable.mergeArray(
                    accountRepo.saveAccountData(accountData),
                    accountRepo.clearArchiveRequestedAt()
                )
            }
    }

    fun prepareData() {
        prepareDataLiveData.add(
            rxLiveDataTransformer.single(
                Single.zip(
                    appRepo.getAutomationScript(),
                    accountRepo.checkFbCredentialExisting(),
                    BiFunction<AutomationScriptData, Boolean, Pair<AutomationScriptData, Boolean>> { script, credentialExisting ->
                        Pair(
                            script,
                            credentialExisting
                        )
                    })
            )
        )
    }

    fun saveArchiveRequestedAt(timestamp: Long) {
        saveArchiveRequestedAtLiveData.add(
            rxLiveDataTransformer.completable(
                accountRepo.setArchiveRequestedAt(timestamp)
            )
        )
    }

    fun checkNotificationEnabled() {
        checkNotificationEnabledLiveData.add(rxLiveDataTransformer.single(appRepo.checkNotificationEnabled()))
    }

    fun getExistingAccountData() {
        getExistingAccountDataLiveData.add(
            rxLiveDataTransformer.single(accountRepo.getAccountData())
        )
    }

}