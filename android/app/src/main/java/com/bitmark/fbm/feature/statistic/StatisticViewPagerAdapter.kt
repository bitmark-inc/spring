/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import android.content.Context
import androidx.fragment.app.FragmentManager
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.util.view.ViewPagerAdapter


class StatisticViewPagerAdapter(
    private val context: Context,
    @Statistic.Type
    type: String,
    fm: FragmentManager
) :
    ViewPagerAdapter(fm) {

    companion object {
        const val WEEK = 0x00
        const val YEAR = 0x01
        const val DECADE = 0x02
    }

    init {
        add(
            StatisticFragment.newInstance(type, Period.WEEK),
            StatisticFragment.newInstance(type, Period.YEAR),
            StatisticFragment.newInstance(type, Period.DECADE)
        )
    }

    override fun getPageTitle(position: Int): CharSequence? {
        return context.getString(
            when (position) {
                WEEK -> R.string.week
                YEAR -> R.string.year
                DECADE -> R.string.decade
                else -> throw IllegalArgumentException("invalid tab pos")
            }
        )
    }
}