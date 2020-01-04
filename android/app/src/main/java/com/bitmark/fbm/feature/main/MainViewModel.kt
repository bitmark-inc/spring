/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.MutableLiveData
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.data.source.remote.api.event.RemoteApiBus
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.auth.FbmServerAuthentication
import io.reactivex.android.schedulers.AndroidSchedulers


class MainViewModel(
    lifecycle: Lifecycle,
    private val fbmServerAuth: FbmServerAuthentication,
    private val remoteApiBus: RemoteApiBus,
    private val appRepo: AppRepository
) :
    BaseViewModel(lifecycle) {

    internal val serviceUnsupportedLiveData = MutableLiveData<String>()

    override fun onCreate() {
        super.onCreate()
        fbmServerAuth.start()
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

    override fun onDestroy() {
        fbmServerAuth.stop()
        super.onDestroy()
    }
}