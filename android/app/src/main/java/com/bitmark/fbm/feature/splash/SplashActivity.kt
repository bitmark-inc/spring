/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import android.os.Bundle
import android.os.Handler
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.activity_splash.*
import javax.inject.Inject

class SplashActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: SplashViewModel

    @Inject
    internal lateinit var navigator: Navigator

    private val handler = Handler()

    override fun layoutRes(): Int = R.layout.activity_splash

    override fun viewModel(): BaseViewModel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.checkLoggedIn()
    }

    override fun initComponents() {
        super.initComponents()

        btnGetStarted.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(OnboardingActivity::class.java)
        }

        tvLogin.setSafetyOnclickListener {

        }
    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.checkLoggedInLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val data = res.data()!!
                    val loggedIn = data.first
                    val dataReady = data.second
                    if (loggedIn) {
                        handler.postDelayed({
                            navigator.anim(RIGHT_LEFT)
                                .startActivityAsRoot(
                                    if (dataReady) {
                                        MainActivity::class.java
                                    } else {
                                        // FIXME for testing
                                        MainActivity::class.java
                                    }
                                )
                        }, 1000)
                    } else {
                        btnGetStarted.visible(true)
                        tvLogin.visible(true)
                    }
                }

                res.isError()   -> {
                    // Unexpected error from shared preference
                }
            }
        })
    }
}