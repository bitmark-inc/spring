/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class AccountData(
    @Expose
    @SerializedName("account_id")
    val accountId: String,

    @Expose
    @SerializedName("auth_required")
    val authRequired: Boolean,

    @Expose
    @SerializedName("key_alias")
    val keyAlias: String
) : Data