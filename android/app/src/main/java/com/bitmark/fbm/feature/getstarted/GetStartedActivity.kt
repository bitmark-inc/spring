/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.getstarted

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_get_started.btnGetStarted
import kotlinx.android.synthetic.main.activity_get_started.tvLogin
import javax.inject.Inject

class GetStartedActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_get_started

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        btnGetStarted.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT)
                    .startActivity(
                            OnboardingActivity::class.java
                    )
        }

        tvLogin.setSafetyOnclickListener {

        }
    }
}