/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.request

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


class ArchiveRequestPayload(
    accountId: String,
    fbId: String,
    password: String
) : Request {

    @SerializedName("account_id")
    @Expose
    private val accountId: String = accountId

    @SerializedName("credential")
    @Expose
    private val credential: Credential = Credential(fbId, password)

}

data class Credential(
    @SerializedName("id")
    @Expose
    private val id: String,

    @SerializedName("password")
    @Expose
    private val password: String
)