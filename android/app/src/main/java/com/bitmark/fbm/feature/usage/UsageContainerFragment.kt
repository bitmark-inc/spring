/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usage

import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.feature.statistic.StatisticFragment
import com.bitmark.fbm.feature.statistic.StatisticViewPagerAdapter
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.google.android.material.tabs.TabLayout
import kotlinx.android.synthetic.main.fragment_usage_container.*
import javax.inject.Inject


class UsageContainerFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = UsageContainerFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    private val tabSelectedListener = object : TabLayout.OnTabSelectedListener {

        override fun onTabReselected(p0: TabLayout.Tab?) {

        }

        override fun onTabUnselected(p0: TabLayout.Tab?) {
        }

        override fun onTabSelected(p0: TabLayout.Tab?) {
        }

    }

    override fun layoutRes(): Int = R.layout.fragment_usage_container

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        val adapter = StatisticViewPagerAdapter(context!!, childFragmentManager)
        adapter.add(
            StatisticFragment.newInstance(StatisticFragment.USAGE, Period.WEEK),
            StatisticFragment.newInstance(StatisticFragment.USAGE, Period.YEAR),
            StatisticFragment.newInstance(StatisticFragment.USAGE, Period.DECADE)
        )
        vpSection.adapter = adapter
        vpSection.offscreenPageLimit = adapter.count
        tabLayout.setupWithViewPager(vpSection)
        tabLayout.addOnTabSelectedListener(tabSelectedListener)

        ivAccount.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }
    }

    override fun deinitComponents() {
        tabLayout.removeOnTabSelectedListener(tabSelectedListener)
        super.deinitComponents()
    }
}