/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.response

import com.bitmark.fbm.data.model.AccountData
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class RegisterAccountResponse(
    @Expose
    @SerializedName("result")
    val data: AccountData
) : Response