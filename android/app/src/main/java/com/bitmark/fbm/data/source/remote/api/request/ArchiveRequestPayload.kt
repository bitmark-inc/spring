/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.request

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class ArchiveRequestPayload(
    @SerializedName("file_url")
    @Expose
    val archiveUrl: String,

    @SerializedName("raw_cookie")
    @Expose
    val cookie: String,

    @Expose
    @SerializedName("started_at")
    val startedAt: Long,

    @Expose
    @SerializedName("ended_at")
    val endedAt: Long
) : Request