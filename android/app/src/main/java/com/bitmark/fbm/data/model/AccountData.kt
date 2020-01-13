/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class AccountData(
    @Expose
    @SerializedName("account_number")
    var id: String,

    @Expose
    @SerializedName("metadata")
    var metadata: Map<String, String>?,

    @Expose
    @SerializedName("created_at")
    var createdAt: String,

    @Expose
    @SerializedName("updated_at")
    var updatedAt: String,

    @Expose
    @SerializedName("auth_required")
    var authRequired: Boolean = false,

    @Expose
    @SerializedName("key_alias")
    var keyAlias: String = ""
) : Data {
    companion object {
        fun newEmptyInstance() = AccountData("", null, "", "", false, "")
    }
}

fun AccountData.isValid() =
    id != "" && createdAt != "" && updatedAt != "" && keyAlias != ""

val AccountData.keyFileName: String
    get() = "${id}.key"

val AccountData.fbIdHash: String?
    get() = if (metadata == null) null else metadata!!["fb-identifier"]

fun AccountData.getMergedMetadata(fbIdHash: String): Map<String, String> {
    return if (metadata == null) {
        mapOf("fb-identifier" to fbIdHash)
    } else {
        val mergedMetadata = metadata!!.toMutableMap()
        mergedMetadata["fb-identifier"] = fbIdHash
        metadata = mergedMetadata.toMap()
        metadata!!
    }
}

fun AccountData.mergeWith(accountData: AccountData): AccountData {
    authRequired = accountData.authRequired
    keyAlias = accountData.keyAlias
    return this
}