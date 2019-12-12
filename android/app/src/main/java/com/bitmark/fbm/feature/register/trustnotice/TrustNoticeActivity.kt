/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.trustnotice

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.register.notification.NotificationActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_trust_notice.*
import javax.inject.Inject


class TrustNoticeActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_trust_notice

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        ivBack.setOnClickListener {
            navigator.anim(Navigator.RIGHT_LEFT)
                .finishActivity()
        }

        btnContinue.setSafetyOnclickListener {
            navigator.anim(Navigator.RIGHT_LEFT)
                .startActivity(NotificationActivity::class.java)
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(Navigator.RIGHT_LEFT).finishActivity()
    }
}