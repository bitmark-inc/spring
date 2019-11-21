/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.auth

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import kotlinx.android.synthetic.main.activity_authentication.*
import javax.inject.Inject


class BiometricAuthActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: BiometricAuthViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    override fun layoutRes(): Int = R.layout.activity_authentication

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        swBiometricAuth.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                dialogController.confirm(
                    R.string.do_you_want_to_allow_to_use_biometric_auth,
                    R.string.app_will_use_biometric,
                    false,
                    R.string.enable,
                    {
                        // TODO some stuffs to enable biometric
                    },
                    R.string.no_thanks,
                    {
                        swBiometricAuth.isChecked = false
                    }
                )
            } else {
                // TODO some stuffs to disable biometric
            }
        }

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}