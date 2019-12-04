/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view.statistic

import android.content.Context
import android.util.AttributeSet
import android.widget.LinearLayout
import androidx.core.content.res.ResourcesCompat
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.modelview.GroupModelView
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.charts.HorizontalBarChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter
import kotlinx.android.synthetic.main.layout_group_header.view.*


class GroupView(context: Context, attrs: AttributeSet?, defStyleAttr: Int) :
    LinearLayout(context, attrs, defStyleAttr) {

    private var viewAdded = false

    companion object {
        private const val CHART_VIEW_INDEX = 1

        private const val MAX_HORIZONTAL_BAR = 5
    }

    constructor(context: Context) : this(context, null, 0)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    init {
        inflate(context, R.layout.layout_group, this)

        orientation = VERTICAL
    }

    fun bind(group: GroupModelView) {
        tvName.text = context.getString(R.string.by_format).format(group.name)
        val vertical = group.name == "day"

        val barXValues = getBarXValues(group)
        val chartView = if (viewAdded) {
            getChildAt(CHART_VIEW_INDEX) as BarChart
        } else {
            buildBarChart(group, barXValues)
        }

        if (!viewAdded) {
            viewAdded = true
            val width = LayoutParams.MATCH_PARENT
            val h = context.getDimensionPixelSize(R.dimen.dp_180)
            val height = if (vertical) h else h * barXValues.size / MAX_HORIZONTAL_BAR
            val params = LayoutParams(width, height)
            val margin = context.getDimensionPixelSize(R.dimen.dp_18)
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
            barEntries.add(BarEntry(index.toFloat(), gEntries[index].yValues))
        }
        val dataSet = BarDataSet(barEntries, "")
        val colors =
            context.resources.getIntArray(R.array.chart_color_palette).take(group.typeCount)
        dataSet.colors = colors
        val barData = BarData(dataSet)
        barData.barWidth = 0.5f
        barData.setValueTextSize(12f)
        barData.setValueTypeface(font)
        barData.setValueFormatter(StackedBarValueFormatter(!vertical))
        return barData
    }

    private fun getBarXValues(group: GroupModelView): List<String> {
        val vertical = group.name == "day"
        val gEntries = group.entries

        return if (vertical) {
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
                        val moy = context.resources.getStringArray(R.array.month_of_year).toList()
                        val index = DateTimeUtil.getMoY(date)
                        moy[index]
                    }
                    Period.DECADE -> {
                        DateTimeUtil.getYear(date).toString().takeLast(2)
                    }
                }
            }
        } else {
            gEntries.map { e -> e.xValue }
        }
    }

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
        xAxis.position = XAxis.XAxisPosition.BOTTOM
        xAxis.valueFormatter = IndexAxisValueFormatter(barXValues)
        xAxis.labelCount = barXValues.size
        chartView.setScaleEnabled(false)
        chartView.isDoubleTapToZoomEnabled = false
        chartView.setPinchZoom(false)
        chartView.isDragEnabled = false
        chartView.legend.isEnabled = false
        chartView.setTouchEnabled(!vertical)
        chartView.isHighlightPerTapEnabled = false
        chartView.isHighlightPerDragEnabled = false
        return chartView
    }
}