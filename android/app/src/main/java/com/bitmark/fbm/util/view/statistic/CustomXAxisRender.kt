/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view.statistic

import android.content.Context
import android.graphics.Canvas
import com.bitmark.fbm.R
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.renderer.XAxisRendererHorizontalBarChart
import com.github.mikephil.charting.utils.MPPointF
import com.github.mikephil.charting.utils.Transformer
import com.github.mikephil.charting.utils.ViewPortHandler


class CustomXAxisRender(
    private val context: Context,
    viewPortHandler: ViewPortHandler, xAxis: XAxis,
    trans: Transformer, chart: BarChart
) : XAxisRendererHorizontalBarChart(viewPortHandler, xAxis, trans, chart) {

    override fun computeSize() {
        val xAxis = (mAxis as? XAxis) ?: return
        xAxis.mLabelWidth = 0
        xAxis.mLabelHeight = 0
        xAxis.mLabelRotatedWidth = 0
        xAxis.mLabelRotatedHeight = 0
    }

    override fun renderAxisLabels(c: Canvas?) {
        if (!mXAxis.isEnabled || !mXAxis.isDrawLabelsEnabled)
            return

        val xoffset = mXAxis.xOffset

        mAxisLabelPaint.typeface = mXAxis.typeface
        mAxisLabelPaint.textSize = mXAxis.textSize
        mAxisLabelPaint.color = mXAxis.textColor

        val pointF = MPPointF.getInstance(0f, 0f)

        when {
            mXAxis.position == XAxis.XAxisPosition.TOP           -> {
                pointF.x = 0.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentRight() + xoffset, pointF)

            }
            mXAxis.position == XAxis.XAxisPosition.TOP_INSIDE    -> {
                pointF.x = 1.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentRight() - xoffset, pointF)

            }
            mXAxis.position == XAxis.XAxisPosition.BOTTOM        -> {
                pointF.x = 1.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentLeft() - xoffset, pointF)

            }
            mXAxis.position == XAxis.XAxisPosition.BOTTOM_INSIDE -> {
                pointF.x = 0.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentLeft() + xoffset, pointF)

            }
            else                                                 -> { // BOTH SIDED
                pointF.x = 0.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentRight() + xoffset, pointF)
                pointF.x = 1.0f
                pointF.y = 0.5f
                drawLabels(c, mViewPortHandler.contentLeft() - xoffset, pointF)
            }
        }

        MPPointF.recycleInstance(pointF)
    }

    override fun drawLabels(c: Canvas?, pos: Float, anchor: MPPointF?) {
        val labelRotationAngleDegrees = mXAxis.labelRotationAngle
        val centeringEnabled = mXAxis.isCenterAxisLabelsEnabled

        val positions = FloatArray(mXAxis.mEntryCount * 2)

        run {
            var i = 0
            while (i < positions.size) {

                // only fill x values
                if (centeringEnabled) {
                    positions[i + 1] = mXAxis.mCenteredEntries[i / 2]
                } else {
                    positions[i + 1] = mXAxis.mEntries[i / 2]
                }
                i += 2
            }
        }

        mTrans.pointValuesToPixel(positions)

        var i = 0
        while (i < positions.size) {

            val y = positions[i + 1]

            if (mViewPortHandler.isInBoundsY(y)) {

                val label = mXAxis.valueFormatter.getAxisLabel(mXAxis.mEntries[i / 2], mXAxis)
                drawLabel(
                    c,
                    label,
                    pos - context.getDimensionPixelSize(R.dimen.dp_3),
                    y - context.getDimensionPixelSize(R.dimen.dp_10),
                    anchor,
                    labelRotationAngleDegrees
                )
            }
            i += 2
        }
    }
}