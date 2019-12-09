/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.insights

import android.content.Context
import android.view.View
import android.view.ViewTreeObserver
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.BehaviorComponent
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.feature.statistic.Statistic.INSIGHTS
import com.bitmark.fbm.feature.statistic.StatisticViewPagerAdapter
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.google.android.material.tabs.TabLayout
import kotlinx.android.synthetic.main.fragment_insights.*
import javax.inject.Inject


class InsightsFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = InsightsFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    private lateinit var adapter: StatisticViewPagerAdapter

    private var scrollY = -1

    private val tabSelectedListener = object : TabLayout.OnTabSelectedListener {

        override fun onTabReselected(p0: TabLayout.Tab?) {
            (adapter.currentFragment as? BaseSupportFragment)?.refresh()
        }

        override fun onTabUnselected(p0: TabLayout.Tab?) {
        }

        override fun onTabSelected(p0: TabLayout.Tab?) {
        }

    }

    override fun layoutRes(): Int = R.layout.fragment_insights

    override fun viewModel(): BaseViewModel? = null

    override fun onAttach(context: Context) {
        super.onAttach(context)
        adapter = StatisticViewPagerAdapter(context, INSIGHTS, childFragmentManager)
    }

    override fun initComponents() {
        super.initComponents()

        vpSection.adapter = adapter
        vpSection.offscreenPageLimit = adapter.count
        tabLayout.setupWithViewPager(vpSection)
        tabLayout.addOnTabSelectedListener(tabSelectedListener)

        sv.viewTreeObserver.addOnGlobalLayoutListener(object :
            ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                val totalHeight = sv.getChildAt(0).height
                val scrollHeight = sv.height
                if (scrollHeight != totalHeight) {
                    sv.viewTreeObserver.removeOnGlobalLayoutListener(this)
                }
                if (scrollY != -1) {
                    sv.scrollTo(0, scrollY)
                }
            }

        })

        ivAccount.setSafetyOnclickListener {
            navigator.anim(Navigator.RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }

        sv.setOnScrollChangeListener { _: View?, _: Int, scrollY: Int, _: Int, _: Int ->
            this.scrollY = scrollY
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