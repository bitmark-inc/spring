/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view.statistic

import android.content.Context
import android.os.Parcelable
import android.util.AttributeSet
import android.widget.LinearLayout
import androidx.core.content.res.ResourcesCompat
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.modelview.GroupModelView
import com.bitmark.fbm.util.modelview.hasAggregatedData
import com.bitmark.fbm.util.modelview.reverse
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.listener.OnChartValueSelectedListener
import kotlinx.android.parcel.Parcelize
import kotlinx.android.parcel.RawValue
import kotlinx.android.synthetic.main.layout_group_header.view.*


class GroupView(context: Context, attrs: AttributeSet?, defStyleAttr: Int) :
    LinearLayout(context, attrs, defStyleAttr) {

    private var chartClickListener: ChartClickListener? = null

    companion object {

        private const val MAX_HORIZONTAL_COUNT = 5

        private const val MAX_VERTICAL_COUNT = 12

        private val stringResLabelMap = mapOf(
            R.string.updates to PostType.UPDATE.value,
            R.string.photos_videos to PostType.MEDIA.value,
            R.string.stories to PostType.STORY.value,
            R.string.links to PostType.LINK.value,
            R.string.like to Reaction.LIKE.value,
            R.string.love to Reaction.LOVE.value,
            R.string.haha to Reaction.HAHA.value,
            R.string.wow to Reaction.WOW.value,
            R.string.sad to Reaction.SAD.value,
            R.string.angry to Reaction.ANGRY.value
        )
    }

    constructor(context: Context) : this(context, null, 0)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    init {
        inflate(context, R.layout.layout_group, this)

        orientation = VERTICAL
    }

    fun setChartClickListener(listener: ChartClickListener) {
        this.chartClickListener = listener
    }

    fun bind(g: GroupModelView) {
        val group = g.copy()
        if (group.name == GroupName.SUB_PERIOD) {
            // sort the sub-period by ascending
            val sortedEntries = group.entries.toMutableList()
            sortedEntries.sortWith(Comparator { o1, o2 ->
                o1.xValue[0].toLong().compareTo(o2.xValue[0].toLong())
            })
            group.entries = sortedEntries
        }
        tvName.text = context.getString(
            when (group.sectionName) {
                SectionName.POST        -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_type
                        GroupName.SUB_PERIOD -> R.string.by_day
                        GroupName.FRIEND     -> R.string.by_friends_tagged
                        GroupName.PLACE      -> R.string.by_place_tagged
                        else                 -> R.string.empty
                    }
                }
                SectionName.REACTION    -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_type
                        GroupName.SUB_PERIOD -> R.string.by_day
                        GroupName.FRIEND     -> R.string.by_friend
                        else                 -> R.string.empty
                    }
                }
                SectionName.MESSAGE     -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_chat
                        GroupName.SUB_PERIOD -> R.string.by_day
                        else                 -> R.string.empty
                    }
                }
                SectionName.AD_INTEREST -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_type
                        GroupName.SUB_PERIOD -> R.string.by_day
                        else                 -> R.string.empty
                    }
                }
                SectionName.ADVERTISER  -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_type
                        GroupName.SUB_PERIOD -> R.string.by_day
                        else                 -> R.string.empty
                    }
                }
                SectionName.LOCATION    -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.by_type
                        GroupName.SUB_PERIOD -> R.string.by_day
                        GroupName.AREA       -> R.string.by_area
                        else                 -> R.string.empty
                    }
                }
                else                    -> R.string.empty
            }
        ).toUpperCase()
        tvNameSuffix.text = context.getString(
            when (group.sectionName) {
                SectionName.REACTION    -> {
                    when (group.name) {
                        GroupName.SUB_PERIOD -> R.string.you_reacted
                        GroupName.FRIEND     -> R.string.you_reacted_to
                        else                 -> R.string.empty
                    }
                }
                SectionName.MESSAGE     -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.with_person_or_group
                        GroupName.SUB_PERIOD -> R.string.sent_or_received
                        else                 -> R.string.empty
                    }
                }
                SectionName.AD_INTEREST -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.of_topic
                        GroupName.SUB_PERIOD -> R.string.fb_tracked_them
                        else                 -> R.string.empty
                    }
                }
                SectionName.ADVERTISER  -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.of_industry
                        GroupName.SUB_PERIOD -> R.string.that_your_data_was_collected
                        else                 -> R.string.empty
                    }
                }
                SectionName.LOCATION    -> {
                    when (group.name) {
                        GroupName.TYPE       -> R.string.of_location
                        GroupName.AREA       -> R.string.of_location
                        GroupName.SUB_PERIOD -> R.string.fb_tracked_them
                        else                 -> R.string.empty
                    }
                }
                else                    -> R.string.empty
            }
        ).toLowerCase()

        val vertical = group.name == GroupName.SUB_PERIOD

        if (!vertical) {
            group.reverse()
        }

        val barXValues = getBarXValues(group)
        val chartView = buildBarChart(group, barXValues)

        val width = if (vertical) {
            calculateVerticalWidth(barXValues.size)
        } else {
            LayoutParams.MATCH_PARENT
        }
        val h = context.getDimensionPixelSize(R.dimen.dp_180)
        val height = if (vertical) h else calculateHorizontalHeight(barXValues.size)
        val params = LayoutParams(width, height)
        val margin = context.getDimensionPixelSize(R.dimen.dp_8)
        params.marginStart = margin
        params.marginEnd = margin

        removeChartView()
        addView(chartView, params)

        val data = getBarData(group, barXValues)
        chartView.data = data
        chartView.notifyDataSetChanged()
    }

    private fun removeChartView() {
        val childCount = childCount
        for (i in 0 until childCount) {
            if (getChildAt(i) is BarChart) {
                removeViewAt(i)
            }
        }
    }

    private fun getBarData(group: GroupModelView, barXValues: List<String>): BarData {
        val font = ResourcesCompat.getFont(context, R.font.grotesk_light_font_family)
        val vertical = group.name == GroupName.SUB_PERIOD
        val gEntries = group.entries
        val barEntries = mutableListOf<BarEntry>()

        for (index in barXValues.indices) {
            val xVal = barXValues[index]
            val resId =
                if (needResIdAsAdditionalData(group)) {
                    stringResLabelMap.entries.first { e -> context.getString(e.key) == xVal }.key
                } else {
                    null
                }
            val periodRange = if (vertical) {
                val periodStartedAt = group.entries[index].xValue.first().toLong() * 1000
                group.period.toSubPeriodRange(periodStartedAt)
            } else {
                null
            }

            val hiddenXVals = if (xVal == context.getString(R.string.others)) {
                group.entries[index].xValue.toList()
            } else {
                null
            }

            val data =
                ChartItem(group.sectionName, group.name, xVal, resId, periodRange, hiddenXVals)

            barEntries.add(
                BarEntry(
                    index.toFloat(),
                    gEntries[index].yValues,
                    data
                )
            )
        }
        val dataSet = BarDataSet(barEntries, "")
        val colors =
            context.resources.getIntArray(
                when (group.sectionName) {
                    SectionName.LOCATION -> R.array.color_palette_1
                    SectionName.REACTION -> R.array.color_palette_2
                    SectionName.POST     -> R.array.color_palette_4
                    else                 -> R.array.color_palette_3
                }
            )
        if (group.name !in arrayOf(GroupName.TYPE, GroupName.AREA)) {
            // reverse all stacked chart
            colors.reverse()
        }
        dataSet.colors = colors.toList()
        val barData = BarData(dataSet)
        barData.barWidth = if (vertical) 0.4f else 0.15f
        barData.setValueTextSize(12f)
        barData.setValueTypeface(font)
        barData.setValueFormatter(StackedBarValueFormatter(!vertical))
        return barData
    }

    private fun calculateHorizontalHeight(xCount: Int) =
        if (xCount == 0) 0 else context.getDimensionPixelSize(R.dimen.dp_180) * xCount / MAX_HORIZONTAL_COUNT + 100 / xCount

    private fun calculateVerticalWidth(xCount: Int) =
        if (xCount == 0) 0 else (0.75f * resources.displayMetrics.widthPixels * xCount / MAX_VERTICAL_COUNT + 100 / xCount).toInt()


    private fun getBarXValues(group: GroupModelView): List<String> {
        val gEntries = group.entries

        return when {
            group.name == GroupName.SUB_PERIOD -> {
                gEntries.map { entry ->
                    val xVal = entry.xValue
                    val periodStartedAt = xVal.first().toLong() * 1000
                    when (group.period) {
                        Period.WEEK   -> {
                            val dow = context.resources.getStringArray(R.array.day_of_week).toList()
                            val index = DateTimeUtil.getDoW(periodStartedAt) - 1
                            dow[index]
                        }
                        Period.YEAR   -> {
                            val moy =
                                context.resources.getStringArray(R.array.month_of_year).toList()
                            val index = DateTimeUtil.getMoY(periodStartedAt)
                            moy[index]
                        }
                        Period.DECADE -> {
                            DateTimeUtil.getYear(periodStartedAt).toString().takeLast(2)
                        }
                    }
                }
            }
            needResIdAsAdditionalData(group)   -> {
                gEntries.map { entry ->
                    context.getString(stringResLabelMap.entries.first { e ->
                        e.value.equals(
                            entry.xValue.first(),
                            true
                        )
                    }.key)
                }
            }

            group.hasAggregatedData()          -> {
                gEntries.map { e ->
                    if (e.xValue.size > 1) {
                        context.getString(R.string.others)
                    } else {
                        e.xValue.first()
                    }
                }
            }

            else                               -> {
                gEntries.map { e -> e.xValue.first() }
            }
        }
    }

    private fun needResIdAsAdditionalData(group: GroupModelView) = group.sectionName in arrayOf(
        SectionName.POST,
        SectionName.REACTION,
        SectionName.AD_INTEREST,
        SectionName.ADVERTISER,
        SectionName.LOCATION
    ) && group.name == GroupName.TYPE

    private fun buildBarChart(group: GroupModelView, barXValues: List<String>): BarChart {
        val font = ResourcesCompat.getFont(context, R.font.grotesk_light_font_family)
        val vertical = group.name == GroupName.SUB_PERIOD
        val chartView = if (vertical) BarChart(context) else HorizontalBarChart(context)
        chartView.description.isEnabled = false
        val axisLeft = chartView.axisLeft
        val axisRight = chartView.axisRight
        val xAxis = chartView.xAxis
        axisLeft.setDrawLabels(false)
        axisLeft.setDrawGridLines(false)
        axisLeft.setDrawAxisLine(false)
        axisLeft.axisMinimum = 0f
        axisRight.setDrawLabels(false)
        axisRight.setDrawGridLines(false)
        axisRight.setDrawAxisLine(false)
        xAxis.setDrawGridLines(false)
        xAxis.setDrawAxisLine(vertical)
        xAxis.textSize = 12f
        xAxis.typeface = font
        xAxis.position =
            if (vertical) XAxis.XAxisPosition.BOTTOM else XAxis.XAxisPosition.BOTTOM_INSIDE
        xAxis.valueFormatter = IndexAxisValueFormatter(barXValues)
        xAxis.labelCount = barXValues.size
        xAxis.isGranularityEnabled = true
        chartView.setScaleEnabled(false)
        chartView.isDoubleTapToZoomEnabled = false
        chartView.setPinchZoom(false)
        chartView.isDragEnabled = false
        chartView.legend.isEnabled = false
        chartView.setTouchEnabled(true)
        chartView.isHighlightPerTapEnabled = true
        chartView.isHighlightPerDragEnabled = false
        chartView.animateY(500)
        chartView.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
            override fun onNothingSelected() {

            }

            override fun onValueSelected(e: Entry?, h: Highlight?) {
                if (chartClickListener != null) {
                    var data = e?.data as? ChartItem ?: return
                    if (data.stringRes != null) {
                        data = ChartItem(
                            data.sectionName,
                            data.groupName,
                            stringResLabelMap[data.stringRes!!]
                                ?: error("could not found item is stringResLabelMap")
                        )
                    }
                    chartClickListener?.onClick(data)
                    postDelayed({ chartView.highlightValues(null) }, 50)
                }
            }
        })
        if (vertical) chartView.setExtraOffsets(0f, 0f, 0f, 15f)
        return chartView
    }

    interface ChartClickListener {

        fun onClick(chartItem: ChartItem)

    }

    @Parcelize
    data class ChartItem(
        val sectionName: SectionName,

        val groupName: GroupName,

        val entryVal: String,

        val stringRes: Int? = null,

        val periodRange: @RawValue LongRange? = null,

        val aggregateVals: List<String>? = null
    ) : Parcelable
}

fun GroupView.ChartItem.getPostType() =
    if (sectionName != SectionName.POST) null else PostType.fromString(entryVal)

fun GroupView.ChartItem.getReaction() =
    if (sectionName != SectionName.REACTION) null else Reaction.fromString(entryVal)