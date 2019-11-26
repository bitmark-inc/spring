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
    archiveUrl: String,
    cookie: String
) : Request {

    @SerializedName("file_url")
    @Expose
    private val archiveUrl: String = archiveUrl

    @SerializedName("raw_cookie")
    @Expose
    private val cookie: String = cookie

}