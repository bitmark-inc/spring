/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import android.os.Handler
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import androidx.core.view.isVisible
import com.aurelhubert.ahbottomnavigation.AHBottomNavigationAdapter
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.BehaviorComponent
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.connectivity.ConnectivityHandler
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.activity_main.*
import javax.inject.Inject

class MainActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: MainViewModel

    @Inject
    internal lateinit var connectivityHandler: ConnectivityHandler

    private val handler = Handler()

    private lateinit var vpAdapter: MainViewPagerAdapter

    override fun layoutRes(): Int = R.layout.activity_main

    override fun viewModel(): BaseViewModel? = viewModel

    private val connectivityChangeListener =
        object : ConnectivityHandler.NetworkStateChangeListener {
            override fun onChange(connected: Boolean) {
                if (!connected) {
                    if (layoutNoNetwork.isVisible) return
                    layoutNoNetwork.visible(true)
                    handler.postDelayed({ layoutNoNetwork.gone(true) }, 2000)
                } else {
                    layoutNoNetwork.gone(true)
                    handler.removeCallbacksAndMessages(null)
                }
            }

        }

    override fun initComponents() {
        super.initComponents()

        val navAdapter = AHBottomNavigationAdapter(this, R.menu.navigation)
        navAdapter.setupWithBottomNavigation(bottomNav)
        bottomNav.defaultBackgroundColor = ContextCompat.getColor(
            this,
            R.color.white
        )
        bottomNav.accentColor =
            ContextCompat.getColor(this, R.color.cognac)
        bottomNav.inactiveColor =
            ContextCompat.getColor(this, R.color.black)
        bottomNav.setTitleTypeface(
            ResourcesCompat.getFont(this, R.font.grotesk_regular)
        )
        bottomNav.setTitleTextSize(
            getDimensionPixelSize(R.dimen.sp_12).toFloat(),
            getDimensionPixelSize(R.dimen.sp_10).toFloat()
        )

        vpAdapter = MainViewPagerAdapter(supportFragmentManager)
        viewPager.offscreenPageLimit = vpAdapter.count
        viewPager.adapter = vpAdapter
        viewPager.setCurrentItem(0, false)

        bottomNav.setOnTabSelectedListener { position, wasSelected ->
            viewPager.setCurrentItem(position, true)

            bottomNav.accentColor =
                ContextCompat.getColor(
                    this, when (position) {
                        0    -> R.color.cognac
                        1    -> R.color.international_klein_blue
                        2    -> R.color.olive
                        else -> error("invalid tab pos")
                    }
                )

            if (wasSelected) {
                (vpAdapter.currentFragment as? BehaviorComponent)?.refresh()
            }

            true
        }

    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun onResume() {
        super.onResume()
        connectivityHandler.addNetworkStateChangeListener(
            connectivityChangeListener
        )
    }

    override fun onPause() {
        super.onPause()
        connectivityHandler.removeNetworkStateChangeListener(
            connectivityChangeListener
        )
    }

    override fun onBackPressed() {
        val currentFragment = vpAdapter.currentFragment as? BehaviorComponent
        if (currentFragment is UsageContainerFragment && !currentFragment.onBackPressed())
            super.onBackPressed()
        else if (currentFragment?.onBackPressed() == false) {
            bottomNav.currentItem = 0
            viewPager.setCurrentItem(0, false)
        }
    }
}