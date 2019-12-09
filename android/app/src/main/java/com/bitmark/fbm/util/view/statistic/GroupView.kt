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
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.modelview.GroupModelView
import com.bitmark.fbm.util.modelview.reverse
import com.bitmark.fbm.util.modelview.sort
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
import kotlinx.android.synthetic.main.layout_group_header.view.*


class GroupView(context: Context, attrs: AttributeSet?, defStyleAttr: Int) :
    LinearLayout(context, attrs, defStyleAttr) {

    private var viewAdded = false

    private var chartClickListener: ChartClickListener? = null

    companion object {
        private const val CHART_VIEW_INDEX = 1

        private const val MAX_HORIZONTAL_COUNT = 5

        private const val MAX_VERTICAL_COUNT = 12

        private val stringResLabelMap = mapOf(
            R.string.updates to "updates",
            R.string.photos to "photos",
            R.string.stories to "stories",
            R.string.videos to "videos",
            R.string.links to "links",
            R.string.like to "like",
            R.string.love to "love",
            R.string.haha to "haha",
            R.string.wow to "wow",
            R.string.sad to "sad",
            R.string.angry to "angry",
            R.string.entertainment to "entertainment",
            R.string.fitness_and_wellness to "fitness_wellness",
            R.string.food_and_drink to "food_drink",
            R.string.hobbies_and_activities to "hobbies_activities",
            R.string.shopping_and_fashion to "shopping_fashion",
            R.string.shopping_center to "shopping_center",
            R.string.restaurant to "restaurant",
            R.string.gym to "gym",
            R.string.park to "park",
            R.string.airport to "airport"
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

    fun bind(group: GroupModelView) {
        tvName.text = context.getString(
            when (group.sectionName) {
                SectionName.POST        -> {
                    when (group.name) {
                        "type"   -> R.string.by_type
                        "day"    -> R.string.by_day
                        "friend" -> R.string.by_friends_tagged
                        "place"  -> R.string.by_place_tagged
                        else     -> R.string.empty
                    }
                }
                SectionName.REACTION    -> {
                    when (group.name) {
                        "type"   -> R.string.by_type
                        "day"    -> R.string.by_day
                        "friend" -> R.string.by_friend
                        else     -> R.string.empty
                    }
                }
                SectionName.MESSAGE     -> {
                    when (group.name) {
                        "type" -> R.string.by_chat
                        "day"  -> R.string.by_day
                        else   -> R.string.empty
                    }
                }
                SectionName.AD_INTEREST -> {
                    when (group.name) {
                        "type" -> R.string.by_type
                        "day"  -> R.string.by_day
                        else   -> R.string.empty
                    }
                }
                SectionName.ADVERTISER  -> {
                    when (group.name) {
                        "type" -> R.string.by_type
                        "day"  -> R.string.by_day
                        else   -> R.string.empty
                    }
                }
                SectionName.LOCATION    -> {
                    when (group.name) {
                        "type" -> R.string.by_type
                        "day"  -> R.string.by_day
                        "area" -> R.string.by_area
                        else   -> R.string.empty
                    }
                }
            }
        ).toUpperCase()
        tvNameSuffix.text = context.getString(
            when (group.sectionName) {
                SectionName.REACTION    -> {
                    when (group.name) {
                        "day"    -> R.string.you_reacted
                        "friend" -> R.string.you_reacted_to
                        else     -> R.string.empty
                    }
                }
                SectionName.MESSAGE     -> {
                    when (group.name) {
                        "type" -> R.string.with_person_or_group
                        "day"  -> R.string.sent_or_received
                        else   -> R.string.empty
                    }
                }
                SectionName.AD_INTEREST -> {
                    when (group.name) {
                        "type" -> R.string.of_topic
                        "day"  -> R.string.fb_tracked_them
                        else   -> R.string.empty
                    }
                }
                SectionName.ADVERTISER  -> {
                    when (group.name) {
                        "type" -> R.string.of_industry
                        "day"  -> R.string.that_your_data_was_collected
                        else   -> R.string.empty
                    }
                }
                SectionName.LOCATION    -> {
                    when (group.name) {
                        "type" -> R.string.of_location
                        "area" -> R.string.of_location
                        "day"  -> R.string.fb_tracked_them
                        else   -> R.string.empty
                    }
                }
                else                    -> R.string.empty
            }
        ).toLowerCase()
        val vertical = group.name == "day"

        if (group.name == "type") {
            if (group.sectionName == SectionName.MESSAGE) {
                group.sort()
            } else {
                group.reverse()
            }
        } else if (group.name != "day") {
            group.sort()
        }

        val barXValues = getBarXValues(group)
        val chartView = if (viewAdded) {
            getChildAt(CHART_VIEW_INDEX) as BarChart
        } else {
            buildBarChart(group, barXValues)
        }

        if (!viewAdded) {
            viewAdded = true
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
            addView(chartView, params)
        }

        val data = getBarData(group, barXValues)
        chartView.data = data
        chartView.notifyDataSetChanged()
    }

    private fun getBarData(group: GroupModelView, barXValues: List<String>): BarData {
        val font = ResourcesCompat.getFont(context, R.font.grotesk)
        val vertical = group.name == "day"
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
            val data = ChartItem(group.sectionName, group.name, xVal, resId)
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
                    SectionName.POST, SectionName.AD_INTEREST, SectionName.LOCATION -> R.array.color_palette_1
                    SectionName.REACTION                                            -> R.array.color_palette_2
                    SectionName.ADVERTISER                                          -> R.array.color_palette_4
                    else                                                            -> R.array.color_palette_3
                }
            )
        if (group.name !in arrayOf("type", "area")) colors.reverse() // reverse all stacked chart
        dataSet.colors = colors.toList()
        val barData = BarData(dataSet)
        barData.barWidth = if (vertical) 0.4f else 0.15f
        barData.setValueTextSize(12f)
        barData.setValueTypeface(font)
        barData.setValueFormatter(StackedBarValueFormatter(!vertical))
        return barData
    }

    private fun calculateHorizontalHeight(xCount: Int) =
        context.getDimensionPixelSize(R.dimen.dp_180) * xCount / MAX_HORIZONTAL_COUNT + 100 / xCount

    private fun calculateVerticalWidth(xCount: Int) =
        (0.75f * resources.displayMetrics.widthPixels * xCount / MAX_VERTICAL_COUNT + 100 / xCount).toInt()


    private fun getBarXValues(group: GroupModelView): List<String> {
        val vertical = group.name == "day"
        val gEntries = group.entries

        return when {
            vertical                         -> {
                gEntries.map { entry ->
                    val xVal = entry.xValue
                    val date = DateTimeUtil.stringToDate(xVal, DateTimeUtil.DATE_FORMAT_7, "UTC")!!
                    when (group.period) {
                        Period.WEEK   -> {
                            val dow = context.resources.getStringArray(R.array.day_of_week).toList()
                            val index = DateTimeUtil.getDoW(date) - 1
                            dow[index]
                        }
                        Period.YEAR   -> {
                            val moy =
                                context.resources.getStringArray(R.array.month_of_year).toList()
                            val index = DateTimeUtil.getMoY(date)
                            moy[index]
                        }
                        Period.DECADE -> {
                            DateTimeUtil.getYear(date).toString().takeLast(2)
                        }
                    }
                }
            }
            needResIdAsAdditionalData(group) -> {

                gEntries.map { entry ->
                    context.getString(stringResLabelMap.entries.first { e ->
                        e.value.equals(
                            entry.xValue,
                            true
                        )
                    }.key)
                }
            }
            else                             -> {
                gEntries.map { e -> e.xValue }
            }
        }
    }

    private fun needResIdAsAdditionalData(group: GroupModelView) = group.sectionName in arrayOf(
        SectionName.POST,
        SectionName.REACTION,
        SectionName.AD_INTEREST,
        SectionName.ADVERTISER,
        SectionName.LOCATION
    ) && group.name == "type"

    private fun buildBarChart(group: GroupModelView, barXValues: List<String>): BarChart {
        val font = ResourcesCompat.getFont(context, R.font.grotesk)
        val vertical = group.name == "day"
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
        chartView.setScaleEnabled(false)
        chartView.isDoubleTapToZoomEnabled = false
        chartView.setPinchZoom(false)
        chartView.isDragEnabled = false
        chartView.legend.isEnabled = false
        chartView.setTouchEnabled(!vertical)
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
        return chartView
    }

    interface ChartClickListener {

        fun onClick(chartItem: ChartItem)

    }

    @Parcelize
    data class ChartItem(
        val sectionName: SectionName,

        val groupName: String,

        val entryVal: String,

        val stringRes: Int? = null
    ) : Parcelable
}