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
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Completable
import io.reactivex.Single

class ArchiveRequestViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val registerAccountLiveData = CompositeLiveData<Any>()

    internal val getAutomationScriptLiveData = CompositeLiveData<AutomationScriptData>()

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
                accountRepo.sendArchiveDownloadRequest(archiveUrl, cookie)
            ).andThen(Single.just(account))
        }.flatMapCompletable { account ->
            account.authRequired = false
            account.keyAlias = alias
            accountRepo.saveAccountData(account)
        }
    }

    fun getAutomationScript() {
        getAutomationScriptLiveData.add(rxLiveDataTransformer.single(appRepo.getAutomationScript()))
    }

    fun saveArchiveRequestedFlag() {
        saveArchiveRequestedFlagLiveData.add(
            rxLiveDataTransformer.completable(
                accountRepo.setArchiveRequested(
                    true
                )
            )
        )
    }
}