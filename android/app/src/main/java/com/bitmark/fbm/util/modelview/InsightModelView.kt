/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview


data class InsightModelView(
    val income: Float?,
    val incomeFrom: Long?,
    val categories: List<String>?
) {

    companion object {

        fun newInstance(income: Float?, incomeFrom: Long?, categories: List<String>?) =
            InsightModelView(income, incomeFrom, categories)
    }
}