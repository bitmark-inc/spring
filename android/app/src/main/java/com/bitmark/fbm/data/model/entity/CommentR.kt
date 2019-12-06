/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class CommentR(
    @Expose
    @SerializedName("timestamp")
    val timestamp: Long,

    @Expose
    @SerializedName("comment")
    val content : String,

    @Expose
    @SerializedName("author")
    val author: String
) : Record