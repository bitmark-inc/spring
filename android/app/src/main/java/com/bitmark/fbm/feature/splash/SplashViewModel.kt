/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Single
import io.reactivex.functions.Function3


class SplashViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val checkLoggedInLiveData = CompositeLiveData<Triple<Boolean, Boolean, Long>>()

    internal val checkVersionOutOfDateLiveData = CompositeLiveData<Boolean>()

    fun checkLoggedIn() {
        checkLoggedInLiveData.add(
            rxLiveDataTransformer.single(
                Single.zip(
                    accountRepo.checkLoggedIn(),
                    appRepo.checkDataReady(),
                    accountRepo.getArchiveRequestedTimestamp(),
                    Function3<Boolean, Boolean, Long, Triple<Boolean, Boolean, Long>> { loggedIn, dataReady, archiveRequested ->
                        Triple(
                            loggedIn,
                            dataReady,
                            archiveRequested
                        )
                    })
            )
        )
    }

    fun checkVersionOutOfDate() {
        checkVersionOutOfDateLiveData.add(rxLiveDataTransformer.single(appRepo.checkVersionOutOfDate()))
    }
}