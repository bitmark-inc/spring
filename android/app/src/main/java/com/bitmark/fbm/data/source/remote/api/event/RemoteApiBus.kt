/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.event

import com.bitmark.fbm.data.source.remote.api.middleware.FbmApiInterceptor
import com.bitmark.fbm.util.Bus
import io.reactivex.subjects.BehaviorSubject


class RemoteApiBus(fbmApiInterceptor: FbmApiInterceptor) : Bus(),
    FbmApiInterceptor.ApiInterceptorListener {

    val serviceStatePublisher = Publisher(BehaviorSubject.create<Boolean>())

    init {
        fbmApiInterceptor.setListener(this)
    }

    override fun onServiceStateChanged(supported: Boolean) {
        serviceStatePublisher.publisher.onNext(supported)
    }
}