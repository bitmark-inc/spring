/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.onboarding

import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.synergy.feature.register.archiverequest.ArchiveRequestActivity
import com.bitmark.synergy.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_onboarding.btnContinue
import kotlinx.android.synthetic.main.activity_onboarding.ivBack
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
                    .startActivity(ArchiveRequestActivity::class.java)
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