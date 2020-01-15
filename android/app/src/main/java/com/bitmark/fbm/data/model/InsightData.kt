/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class InsightData(
    @Expose
    @SerializedName("fb_income")
    val fbIncome: Float,

    @Expose
    @SerializedName("fb_income_from")
    val fbIncomeFrom: Long
) : Data {
    companion object
}

fun InsightData.Companion.newDefaultInstance() = InsightData(-1f, 0)

