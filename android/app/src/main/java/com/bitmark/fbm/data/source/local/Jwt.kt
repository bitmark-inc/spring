/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local


class Jwt private constructor() {

    companion object {

        @Volatile
        private var INSTANCE: Jwt? = null

        fun getInstance(): Jwt {
            if (null == INSTANCE) {
                synchronized(Jwt::class) {
                    if (null == INSTANCE) {
                        INSTANCE =
                            Jwt()
                    }
                }
            }
            return INSTANCE!!
        }
    }

    var token: String = ""

    var expiredAt: Long = -1L

    fun clear() {
        token = ""
        expiredAt = -1L
    }
}