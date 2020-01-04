/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.MutableLiveData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.data.source.remote.api.event.RemoteApiBus
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import io.reactivex.android.schedulers.AndroidSchedulers


class ArchiveRequestContainerViewModel(
    lifecycle: Lifecycle,
    private val accountRepo: AccountRepository,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer,
    private val remoteApiBus: RemoteApiBus
) : BaseViewModel(lifecycle) {

    internal val getArchiveRequestedAt = CompositeLiveData<Long>()

    internal val serviceUnsupportedLiveData = MutableLiveData<String>()

    fun getArchiveRequestedAt() {
        getArchiveRequestedAt.add(
            rxLiveDataTransformer.single(
                accountRepo.getArchiveRequestedAt()
            )
        )
    }

    override fun onStart() {
        super.onStart()
        remoteApiBus.serviceStatePublisher.subscribe(this) { supported ->
            if (supported) return@subscribe
            subscribe(appRepo.getUpdateAppUrl().observeOn(AndroidSchedulers.mainThread())
                .subscribe { url, e ->
                    if (e == null) {
                        serviceUnsupportedLiveData.value = url
                    } else {
                        serviceUnsupportedLiveData.value = ""
                    }
                })
        }
    }

    override fun onStop() {
        remoteApiBus.unsubscribe(this)
        super.onStop()
    }
}