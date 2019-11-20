/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import com.aurelhubert.ahbottomnavigation.AHBottomNavigationAdapter
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.BehaviorComponent
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.setTextColorRes
import kotlinx.android.synthetic.main.activity_main.*
import javax.inject.Inject

class MainActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_main

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        val navAdapter = AHBottomNavigationAdapter(this, R.menu.navigation)
        navAdapter.setupWithBottomNavigation(bottomNav)
        bottomNav.defaultBackgroundColor = ContextCompat.getColor(
            this,
            R.color.white
        )
        bottomNav.accentColor =
            ContextCompat.getColor(this, R.color.colorAccent)
        bottomNav.inactiveColor =
            ContextCompat.getColor(this, R.color.black)
        bottomNav.setTitleTypeface(
            ResourcesCompat.getFont(this, R.font.grotesk_regular)
        )
        bottomNav.setTitleTextSize(
            getDimensionPixelSize(R.dimen.sp_12).toFloat(),
            getDimensionPixelSize(R.dimen.sp_10).toFloat()
        )

        val adapter = MainViewPagerAdapter(supportFragmentManager)
        viewPager.offscreenPageLimit = adapter.count
        viewPager.adapter = adapter
        viewPager.setCurrentItem(0, false)

        bottomNav.setOnTabSelectedListener { position, wasSelected ->
            viewPager.setCurrentItem(position, false)

            when (position) {
                MainViewPagerAdapter.TAB_USAGE    -> {
                    tvTitle.text = getString(R.string.usage)
                    tvMsg.text = getString(R.string.how_you_use_fb)
                    tvTitle.setTextColorRes(R.color.cognac)
                }

                MainViewPagerAdapter.TAB_INSIGHTS -> {
                    tvTitle.text = getString(R.string.insights)
                    tvMsg.text = getString(R.string.how_fb_use_you)
                    tvTitle.setTextColorRes(R.color.international_klein_blue)
                }

                MainViewPagerAdapter.TAB_OFFER    -> {
                    tvTitle.text = getString(R.string.offer)
                    tvMsg.text = getString(R.string.for_your_fb_data)
                    tvTitle.setTextColorRes(R.color.olive)
                }
            }

            if (wasSelected) {
                (adapter.currentFragment as? BehaviorComponent)?.refresh()
            }

            true
        }

        ivAccount.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }

    }
}