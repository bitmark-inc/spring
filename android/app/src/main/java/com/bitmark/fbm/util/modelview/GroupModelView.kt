/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.Period


data class GroupModelView(
    val period: Period,
    val sectionName: String,
    val name: String,
    val typeCount: Int,
    var entries: List<Entry>
) : ModelView {

    fun reversed() {
        entries = entries.reversed()
    }

    fun sort() {
        entries = entries.sortedBy { e -> e.yValues.sum() }
    }
}

data class Entry(val xValue: String, val yValues: FloatArray)

