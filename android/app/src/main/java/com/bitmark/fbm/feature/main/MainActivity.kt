/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.main

import android.os.Handler
import androidx.core.view.isVisible
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.*
import com.bitmark.fbm.feature.connectivity.ConnectivityHandler
import com.bitmark.fbm.feature.main.MainViewPagerAdapter.Companion.TAB_INSIGHT
import com.bitmark.fbm.feature.main.MainViewPagerAdapter.Companion.TAB_LENS
import com.bitmark.fbm.feature.main.MainViewPagerAdapter.Companion.TAB_USAGE
import com.bitmark.fbm.feature.usage.UsageContainerFragment
import com.bitmark.fbm.util.ext.*
import kotlinx.android.synthetic.main.activity_main.*
import javax.inject.Inject

class MainActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: MainViewModel

    @Inject
    internal lateinit var connectivityHandler: ConnectivityHandler

    @Inject
    internal lateinit var dialogController: DialogController

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

        vpAdapter = MainViewPagerAdapter(supportFragmentManager)
        viewPager.offscreenPageLimit = vpAdapter.count
        viewPager.adapter = vpAdapter
        viewPager.setCurrentItem(TAB_USAGE, false)

        bottomNav.setActiveItem(TAB_USAGE)
        bottomNav.setIndicatorWidth(screenWidth / vpAdapter.count.toFloat())

        bottomNav.onItemSelected = { pos ->
            viewPager.setCurrentItem(pos, true)

            val color = when (pos) {
                TAB_USAGE   -> R.color.cognac
                TAB_INSIGHT -> R.color.international_klein_blue
                TAB_LENS    -> R.color.olive
                else        -> error("invalid tab pos")
            }

            bottomNav.setActiveColor(color)
        }

        bottomNav.onItemReselected = {
            (vpAdapter.currentFragment as? BehaviorComponent)?.refresh()
        }

    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.serviceUnsupportedLiveData.observe(this, Observer { url ->
            dialogController.showUpdateRequired {
                if (url.isEmpty()) {
                    navigator.goToPlayStore()
                } else {
                    navigator.goToUpdateApp(url)
                }
                navigator.exitApp()
            }
        })
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
            bottomNav.setActiveItem(TAB_USAGE, R.color.cognac)
            viewPager.setCurrentItem(TAB_USAGE, false)
        }
    }
}