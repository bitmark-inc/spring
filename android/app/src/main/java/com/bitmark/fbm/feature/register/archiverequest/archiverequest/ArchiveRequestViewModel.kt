/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.archiverequest

import androidx.lifecycle.Lifecycle
import com.bitmark.cryptography.crypto.Sha3256
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.data.model.AutomationScriptData
import com.bitmark.fbm.data.model.CredentialData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.functions.BiFunction

class ArchiveRequestViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val registerAccountLiveData = CompositeLiveData<Any>()

    internal val prepareDataLiveData =
        CompositeLiveData<Pair<AutomationScriptData, CredentialData>>()

    internal val checkNotificationEnabledLiveData = CompositeLiveData<Boolean>()

    internal val saveArchiveRequestedFlagLiveData = CompositeLiveData<Any>()

    fun registerAccount(
        requester: String,
        timestamp: String,
        signature: String,
        archiveUrl: String,
        cookie: String,
        alias: String
    ) {
        registerAccountLiveData.add(
            rxLiveDataTransformer.completable(
                registerAccountStream(requester, timestamp, signature, archiveUrl, cookie, alias)
            )
        )
    }

    private fun registerAccountStream(
        requester: String,
        timestamp: String,
        signature: String,
        archiveUrl: String,
        cookie: String,
        alias: String
    ): Completable {
        return accountRepo.registerFbmServerAccount(
            timestamp,
            signature,
            requester
        ).flatMap { account ->
            val intercomId =
                "FBM_android_%s".format(Sha3256.hash(RAW.decode(account.id)))
            Completable.mergeArray(
                accountRepo.registerIntercomUser(intercomId),
                accountRepo.sendArchiveDownloadRequest(archiveUrl, cookie),
                appRepo.registerNotificationService(mapOf(requester to "account_id"))
            ).andThen(Single.just(account))
        }.flatMapCompletable { account ->
            account.authRequired = false
            account.keyAlias = alias
            accountRepo.saveAccountData(account)
        }
    }

    fun prepareData() {
        prepareDataLiveData.add(
            rxLiveDataTransformer.single(
                Single.zip(
                    appRepo.getAutomationScript(),
                    accountRepo.getFbCredential(),
                    BiFunction { script, credential ->
                        Pair(
                            script,
                            credential
                        )
                    })
            )
        )
    }

    fun saveArchiveRequestedFlag(timestamp: Long) {
        saveArchiveRequestedFlagLiveData.add(
            rxLiveDataTransformer.completable(
                accountRepo.setArchiveRequestedTime(timestamp)
            )
        )
    }

    fun checkNotificationEnabled() {
        checkNotificationEnabledLiveData.add(rxLiveDataTransformer.single(appRepo.checkNotificationEnabled()))
    }
}