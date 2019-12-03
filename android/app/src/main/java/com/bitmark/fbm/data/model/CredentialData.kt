/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class CredentialData(
    @Expose
    @SerializedName("id")
    val id: String,

    @Expose
    @SerializedName("password")
    val password: String
) : Data {
    companion object {
        fun newInstance() = CredentialData("", "")
    }

    fun isValid() = id.isNotBlank() && password.isNotBlank()
}