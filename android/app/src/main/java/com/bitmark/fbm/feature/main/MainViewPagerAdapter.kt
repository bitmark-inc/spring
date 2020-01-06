/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import com.bitmark.fbm.feature.insights.InsightsContainerFragment
import com.bitmark.fbm.feature.lens.LensContainerFragment
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.util.view.ViewPagerAdapter

class MainViewPagerAdapter(fm: FragmentManager) : ViewPagerAdapter(fm) {

    companion object {
        const val TAB_USAGE = 0x00
        const val TAB_INSIGHT = 0x01
        const val TAB_LENS = 0x02
    }

    init {
        super.add(
            UsageContainerFragment.newInstance(),
            InsightsContainerFragment.newInstance(),
            LensContainerFragment.newInstance()
        )
    }

    override fun add(vararg fragments: Fragment) {
        throw UnsupportedOperationException("not support")
    }

}