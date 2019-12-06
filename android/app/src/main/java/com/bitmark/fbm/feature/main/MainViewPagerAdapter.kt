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
import com.bitmark.fbm.feature.stream.StreamContainerFragment
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.util.view.ViewPagerAdapter

class MainViewPagerAdapter(fm: FragmentManager) : ViewPagerAdapter(fm) {

    init {
        super.add(
            UsageContainerFragment.newInstance(),
            InsightsContainerFragment.newInstance(),
            StreamContainerFragment.newInstance()
        )
    }

    override fun add(vararg fragments: Fragment) {
        throw UnsupportedOperationException("not support")
    }

}