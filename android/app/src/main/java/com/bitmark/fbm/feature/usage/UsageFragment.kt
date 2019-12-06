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
import com.bitmark.fbm.feature.BehaviorComponent
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.feature.statistic.StatisticFragment
import com.bitmark.fbm.feature.statistic.StatisticViewPagerAdapter
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.google.android.material.tabs.TabLayout
import kotlinx.android.synthetic.main.fragment_usage.*
import javax.inject.Inject


class UsageFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = UsageFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    private lateinit var adapter: StatisticViewPagerAdapter

    private val tabSelectedListener = object : TabLayout.OnTabSelectedListener {

        override fun onTabReselected(p0: TabLayout.Tab?) {
            (adapter.currentFragment as? BaseSupportFragment)?.refresh()
        }

        override fun onTabUnselected(p0: TabLayout.Tab?) {
        }

        override fun onTabSelected(p0: TabLayout.Tab?) {
        }

    }

    override fun layoutRes(): Int = R.layout.fragment_usage

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        adapter = StatisticViewPagerAdapter(context!!, childFragmentManager)
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
            navigator.anim(Navigator.RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }
    }

    override fun deinitComponents() {
        tabLayout.removeOnTabSelectedListener(tabSelectedListener)
        super.deinitComponents()
    }

    override fun refresh() {
        super.refresh()
        if (vpSection.currentItem != StatisticViewPagerAdapter.WEEK) {
            vpSection.currentItem = StatisticViewPagerAdapter.WEEK
        } else {
            (adapter.currentFragment as? BehaviorComponent)?.refresh()
        }
    }

    override fun onBackPressed(): Boolean {
        super.onBackPressed()
        return if (vpSection.currentItem != StatisticViewPagerAdapter.WEEK) {
            vpSection.currentItem = StatisticViewPagerAdapter.WEEK
            true
        } else {
            false
        }
    }
}