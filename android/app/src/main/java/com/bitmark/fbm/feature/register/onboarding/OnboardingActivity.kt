/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.onboarding

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.notification.NotificationActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_onboarding.*
import javax.inject.Inject

class OnboardingActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_onboarding

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        btnContinue.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT)
                .startActivity(NotificationActivity::class.java)
        }

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT)
                .finishActivity()
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT)
            .finishActivity()
    }
}