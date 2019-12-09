/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.*


data class SectionModelView(
    val name: SectionName,
    val period: Period,
    val quantity: Int,
    val diffFromPrev: Int,
    val average: Int,
    val groups: List<GroupModelView>
) : ModelView {
    companion object {

        fun newInstance(sectionR: SectionR, avg: Int): SectionModelView {
            val sectionName = sectionR.name
            val period = sectionR.period
            val quantity = sectionR.quantity
            val diffFromPrev = sectionR.diffFromPrev
            val groups = mutableListOf<GroupModelView>()

            // by area if has
            if (sectionName == SectionName.LOCATION) {
                val types = sectionR.getGroup<GroupEntity>(GroupName.AREA)
                val typesCount = types.data.size
                val typeEntries =
                    types.data.entries.map { e ->
                        Entry(
                            e.key,
                            floatArrayOf(e.value.toFloat())
                        )
                    }
                groups.add(
                    GroupModelView(
                        period,
                        sectionName,
                        GroupName.AREA,
                        typesCount,
                        typeEntries
                    )
                )
            }

            // by type
            val types = sectionR.getGroup<GroupEntity>(GroupName.TYPE)
            val typesCount = types.data.size
            val typeEntries =
                types.data.entries.map { e ->
                    Entry(
                        e.key,
                        floatArrayOf(e.value.toFloat())
                    )
                }
            groups.add(
                GroupModelView(
                    period,
                    sectionName,
                    GroupName.TYPE,
                    typesCount,
                    typeEntries
                )
            )


            for (entry in sectionR.groups.entries) {
                val groupName = GroupName.fromString(entry.key)
                if (groupName == GroupName.TYPE || groupName == GroupName.AREA) continue
                val group = sectionR.getArrayGroup<GroupEntity>(groupName)
                val entries = group.map { e ->
                    val xVal = e.name.capitalize()
                    val yVals = e.data.entries.map { e -> e.value.toFloat() }.toFloatArray()
                    Entry(xVal, yVals)
                }
                groups.add(
                    GroupModelView(
                        period,
                        sectionName,
                        groupName,
                        typesCount,
                        entries
                    )
                )
            }

            return SectionModelView(sectionName, period, quantity, diffFromPrev, avg, groups)
        }
    }
}