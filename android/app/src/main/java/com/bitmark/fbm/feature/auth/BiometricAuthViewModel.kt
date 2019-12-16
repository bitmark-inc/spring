/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.auth

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer


class BiometricAuthViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val getAccountDataLiveData = CompositeLiveData<AccountData>()

    internal val saveAccountKeyDataLiveData = CompositeLiveData<Any>()

    fun getAccountData() {
        getAccountDataLiveData.add(rxLiveDataTransformer.single(accountRepo.getAccountData()))
    }

    fun saveAccountKeyData(alias: String, authRequired: Boolean) {
        saveAccountKeyDataLiveData.add(
            rxLiveDataTransformer.completable(
                accountRepo.saveAccountKeyData(
                    alias, authRequired
                )
            )
        )
    }
}