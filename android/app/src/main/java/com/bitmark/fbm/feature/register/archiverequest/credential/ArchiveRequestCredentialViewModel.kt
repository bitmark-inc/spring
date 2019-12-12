/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.credential

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer


class ArchiveRequestCredentialViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val saveFbCredentialLiveData = CompositeLiveData<Any>()

    fun saveFbCredentialAlias(alias: String) {
        saveFbCredentialLiveData.add(
            rxLiveDataTransformer.completable(
                accountRepo.saveFbCredentialAlias(alias)
            )
        )
    }
}