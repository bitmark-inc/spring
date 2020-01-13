/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.credential

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.CredentialData
import com.bitmark.fbm.data.model.fbIdHash
import com.bitmark.fbm.data.model.hashId
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.schedulers.Schedulers


class ArchiveRequestCredentialViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val verifyFbAccountLiveData = CompositeLiveData<Boolean>()

    fun verifyFbAccount(id: String) {
        val stream =
            accountRepo.getAccountData().observeOn(Schedulers.computation()).map { accountData ->
                val processedFbIdHash = accountData.fbIdHash
                val fbIdHash = CredentialData.hashId(id)
                processedFbIdHash == null || processedFbIdHash == fbIdHash
            }
        verifyFbAccountLiveData.add(rxLiveDataTransformer.single(stream))
    }
}