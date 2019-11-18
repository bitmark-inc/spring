/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.notification

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.Completable

class RegisterNotificationViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(
    lifecycle
) {

    internal val registerNotificationLiveData = CompositeLiveData<Any>()

    internal val checkNotificationServiceRegistrationLiveData = CompositeLiveData<Boolean>()

    fun registerNotification() {
        registerNotificationLiveData.add(
            rxLiveDataTransformer.completable(accountRepo.getAccountInfo().flatMapCompletable { account ->
                Completable.fromCallable {
                    appRepo.registerNotificationService(mapOf("account_id" to account.accountId))
                }
            })
        )
    }

    fun checkNotificationServiceRegistration() {
        checkNotificationServiceRegistrationLiveData.add(
            rxLiveDataTransformer.single(appRepo.checkNotificationServiceRegistration())
        )
    }

}