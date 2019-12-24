/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.*
import kotlin.math.roundToInt


data class SectionModelView(
    val name: SectionName,
    val period: Period,
    val quantity: Int,
    val diffFromPrev: Int,
    val average: Int,
    val groups: List<GroupModelView>
) : ModelView {
    companion object {

        private const val THRESHOLD_VALS_COUNT = 4

        fun newDefaultInstance(name: SectionName, period: Period) =
            SectionModelView(name, period, 0, 0, 0, listOf())

        fun newInstance(sectionR: SectionR, avg: Int): SectionModelView {
            val sectionName = sectionR.name
            val period = sectionR.period
            val quantity = sectionR.quantity
            val diffFromPrev = sectionR.diffFromPrev
            val groupModelViews = mutableListOf<GroupModelView>()
            val typesCount: Int // total count of stack
            var hasAggregatedType = false

            if (sectionName != SectionName.LOCATION) {
                val types = sectionR.getGroup<GroupEntity>(GroupName.TYPE)
                typesCount = when (sectionName) {
                    SectionName.POST     -> 4
                    SectionName.REACTION -> 6
                    else                 -> error("unsupported section")
                }

                val data = types.data
                val entries = (0 until typesCount).map { i ->
                    val xVal = when (sectionName) {
                        SectionName.POST     -> PostType.fromIndex(i).value
                        SectionName.REACTION -> Reaction.fromIndex(i).value
                        else                 -> error("unsupported section")
                    }
                    val yVal = if (data.containsKey(xVal)) data[xVal] else 0
                    Entry(arrayOf(xVal), floatArrayOf(yVal!!.toFloat()))
                }

                groupModelViews.add(
                    GroupModelView(
                        period,
                        sectionName,
                        GroupName.TYPE,
                        typesCount,
                        entries
                    )
                )
            } else {
                val types = sectionR.getGroup<GroupEntity>(GroupName.AREA)
                val entityData = types.data.entries.sortedByDescending { e -> e.value }
                hasAggregatedType = entityData.size > THRESHOLD_VALS_COUNT
                val topEntityData =
                    if (hasAggregatedType) entityData.take(THRESHOLD_VALS_COUNT) else entityData
                val entries = topEntityData.map { e ->
                    Entry(
                        arrayOf(e.key),
                        floatArrayOf(e.value.toFloat())
                    )
                }.toMutableList()

                if (hasAggregatedType) {
                    val topEntityKey = topEntityData.map { e -> e.key }
                    val aggregateData = entityData.filterNot { d -> d.key in topEntityKey }
                    val aggregateEntry = Entry(
                        aggregateData.map { d -> d.key }.toTypedArray(),
                        floatArrayOf(aggregateData.sumBy { d -> d.value }.toFloat())
                    )
                    entries.add(aggregateEntry)
                }
                typesCount = entries.size

                groupModelViews.add(
                    0,
                    GroupModelView(
                        period,
                        sectionName,
                        GroupName.AREA,
                        typesCount,
                        entries
                    )
                )
            }

            for (gEntry in sectionR.groups.entries) {
                val groupName = GroupName.fromString(gEntry.key)
                if (groupName == GroupName.TYPE || groupName == GroupName.AREA) continue
                var groupEntities = sectionR.getArrayGroup<GroupEntity>(groupName)
                if (groupName != GroupName.SUB_PERIOD) {
                    groupEntities =
                        groupEntities.sortedByDescending { g -> g.data.entries.sumBy { e -> e.value } }
                } else {
                    val dateRange = period.toPeriodRange(sectionR.periodStartedAt)
                    if (groupEntities.size < dateRange.size) {
                        // fill missing records
                        val newGroupEntities = dateRange.map { dateMillis ->
                            val name = (dateMillis / 1000).toString()
                            GroupEntity(
                                name,
                                groupEntities.find { e -> e.name == name }?.data ?: mapOf()
                            )
                        }
                        groupEntities = newGroupEntities
                    }
                }

                val needAggregate =
                    groupName != GroupName.SUB_PERIOD && groupEntities.size > THRESHOLD_VALS_COUNT
                val topGroupEntities =
                    if (needAggregate) groupEntities.take(THRESHOLD_VALS_COUNT) else groupEntities
                val entries = topGroupEntities.map { g ->
                    val xVal = g.name.replace("'", "")
                    val yValues = FloatArray(typesCount) { 0f }
                    val data = g.data.entries
                    data.forEachIndexed { i, e ->
                        val key = e.key
                        val index = when (sectionName) {
                            SectionName.POST     -> PostType.indexOf(key)
                            SectionName.REACTION -> Reaction.indexOf(key)
                            SectionName.LOCATION -> {
                                if (hasAggregatedType) {
                                    val aggregateMV =
                                        groupModelViews.find { g -> g.hasAggregatedData() }!!
                                    val aggregateIndex = aggregateMV.aggregatedIndex()
                                    val aggregateVals = aggregateMV.entries[aggregateIndex].xValue
                                    if (key in aggregateVals) {
                                        aggregateIndex
                                    } else {
                                        val mv =
                                            groupModelViews.find { g -> g.name == GroupName.AREA }!!
                                        mv.entries.indexOfFirst { e -> e.xValue.contains(key) }
                                    }
                                } else {
                                    i
                                }
                            }
                            else                 -> error("unsupported section")
                        }
                        yValues[index] += e.value.toFloat()
                    }
                    Entry(arrayOf(xVal), yValues)
                }.toMutableList()

                if (needAggregate) {
                    val topGroupName = topGroupEntities.map { g -> g.name }
                    val aggregateData = groupEntities.filterNot { g -> g.name in topGroupName }
                    val aggregateEntry = Entry(
                        aggregateData.map { d -> d.name }.toTypedArray(),
                        floatArrayOf(aggregateData.sumBy { d -> d.sum() }.toFloat())
                    )
                    entries.add(aggregateEntry)
                }

                groupModelViews.add(
                    GroupModelView(
                        period,
                        sectionName,
                        groupName,
                        typesCount,
                        entries
                    )
                )
            }

            return SectionModelView(
                sectionName,
                period,
                quantity,
                (diffFromPrev * 100).roundToInt(),
                avg,
                groupModelViews
            )
        }
    }

    fun isNoData() = groups.isEmpty()
}