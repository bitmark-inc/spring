/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class JwtData(
    @SerializedName("jwt_token")
    @Expose
    val token: String,

    @SerializedName("expired_in")
    @Expose
    val expiredIn: Long
) : Data