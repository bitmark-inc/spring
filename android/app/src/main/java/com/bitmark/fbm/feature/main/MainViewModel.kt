/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.auth.FbmServerAuthentication


class MainViewModel(lifecycle: Lifecycle, private val fbmServerAuth: FbmServerAuthentication) :
    BaseViewModel(lifecycle) {

    override fun onCreate() {
        super.onCreate()
        fbmServerAuth.start()
    }

    override fun onDestroy() {
        fbmServerAuth.stop()
        super.onDestroy()
    }
}