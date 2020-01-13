/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.GroupName
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName

data class GroupModelView(
    val period: Period,
    val sectionName: SectionName,
    val name: GroupName,
    val typeCount: Int,
    var entries: List<Entry>
) : ModelView

fun GroupModelView.reverse() {
    entries = entries.reversed()
}

fun GroupModelView.order() = when (name) {
    GroupName.TYPE -> 0
    GroupName.SUB_PERIOD -> -1
    GroupName.FRIEND -> -2
    GroupName.PLACE -> -3
}

fun GroupModelView.hasAggregatedData() = aggregatedIndex() != -1

fun GroupModelView.aggregatedIndex() = entries.indexOfFirst { e -> e.isAggregated() }

data class Entry(val xValue: Array<String>, val yValues: FloatArray)

fun Entry.sum() = yValues.sum()

fun Entry.isAggregated() = xValue.size > 1

