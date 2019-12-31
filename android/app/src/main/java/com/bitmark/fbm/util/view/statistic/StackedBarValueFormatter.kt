/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view.statistic

import com.bitmark.fbm.util.ext.abbreviate
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.formatter.ValueFormatter


class StackedBarValueFormatter(private val isHorizontal: Boolean) : ValueFormatter() {

    private var lastEntry: BarEntry? = null

    private var iteratedStackIndex = 0

    override fun getFormattedValue(value: Float): String {
        return value.toDouble().abbreviate()
    }

    override fun getBarStackedLabel(value: Float, stackedEntry: BarEntry?): String {
        if (stackedEntry == lastEntry) {
            iteratedStackIndex++
        }

        val yVals = stackedEntry!!.yVals
        val topNonZeroIndex = yVals.indexOfLast { v -> v != 0f }
        val nonZeroCount = yVals.count { v -> v != 0f }
        val thresholdIndex =
            if (nonZeroCount == 0) yVals.size - 1 else if (isHorizontal) yVals.size - 1 else nonZeroCount - 1
        val yValLabelIndex =
            if (nonZeroCount == 0) yVals.size - 1 else if (isHorizontal) topNonZeroIndex else nonZeroCount - 1

        val v = when (yValLabelIndex) {
            iteratedStackIndex -> {
                stackedEntry.y.toDouble().abbreviate()
            }
            else               -> ""
        }

        if (iteratedStackIndex == thresholdIndex) {
            iteratedStackIndex = 0
            lastEntry = null
        }

        lastEntry = stackedEntry
        return v
    }

}