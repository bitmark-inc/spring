/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.bitmark.apiservice.params.RegistrationParams
import com.bitmark.cryptography.crypto.Sha3512
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class ArchiveData(
    @Expose
    @SerializedName("id")
    val id: Long,

    @Expose
    @SerializedName("started_at")
    val startedAt: String,

    @Expose
    @SerializedName("ended_at")
    val endedAt: String,

    @Expose
    @SerializedName("status")
    val status: ArchiveStatus,

    @Expose
    @SerializedName("created_at")
    val createdAt: String,

    @Expose
    @SerializedName("updated_at")
    val updatedAt: String,

    @Expose
    @SerializedName("content_hash")
    val hash: String
) : Data

fun ArchiveData.isValid() = status != ArchiveStatus.INVALID

fun ArchiveData.isProcessed() = status == ArchiveStatus.PROCESSED

val ArchiveData.metaData: Map<String, String>
    get() = mapOf(
        "id" to id.toString(),
        "started_at" to startedAt,
        "ended_at" to endedAt,
        "created_at" to createdAt,
        "updated_at" to updatedAt,
        "content_hash" to hash
    )

val ArchiveData.hashBytes: ByteArray
    get() = HEX.decode(hash)

val ArchiveData.assetId: String
    get() = HEX.encode(Sha3512.hash(RAW.decode(RegistrationParams.computeFingerprint(hashBytes))))

enum class ArchiveStatus {
    @Expose
    @SerializedName("submitted")
    SUBMITTED,

    @Expose
    @SerializedName("stored")
    STORED,

    @Expose
    @SerializedName("processed")
    PROCESSED,

    @Expose
    @SerializedName("invalid")
    INVALID
}