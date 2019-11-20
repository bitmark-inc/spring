/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.insights

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel


class InsightsContainerFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = InsightsContainerFragment()
    }

    override fun layoutRes(): Int = R.layout.fragment_insights_container

    override fun viewModel(): BaseViewModel? = null
}