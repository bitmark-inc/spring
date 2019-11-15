/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.getstarted

import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.synergy.feature.register.onboarding.OnboardingActivity
import com.bitmark.synergy.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_get_started.btnGetStarted
import kotlinx.android.synthetic.main.activity_get_started.tvAlreadyHaveAccount
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
                            OnboardingActivity::class.java)
        }

        tvAlreadyHaveAccount.setSafetyOnclickListener {

        }
    }
}