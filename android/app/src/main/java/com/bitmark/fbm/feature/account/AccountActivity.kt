/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.account

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.auth.BiometricAuthActivity
import com.bitmark.fbm.feature.recovery.RecoveryContainerActivity
import com.bitmark.fbm.feature.unlink.UnlinkContainerActivity
import com.bitmark.fbm.util.ext.openBrowser
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import io.intercom.android.sdk.Intercom
import kotlinx.android.synthetic.main.activity_account.*
import javax.inject.Inject


class AccountActivity : BaseAppCompatActivity() {

    companion object {

        private const val SURVEY_URL =
            "https://docs.google.com/forms/d/e/1FAIpQLScL41kNU6SBzo7ndcraUf7O-YJ_JrPqg_rlI588UjLK-_sGtQ/viewform?usp=sf_link"

        fun newInstance() = AccountActivity()
    }

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_account

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

        tvUnlink.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(UnlinkContainerActivity::class.java)
        }

        tvBiometricAuth.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(BiometricAuthActivity::class.java)
        }

        tvRecoveryKey.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(RecoveryContainerActivity::class.java)
        }

//        tvAbout.setSafetyOnclickListener {
//            val bundle = SupportActivity.getBundle(
//                getString(R.string.about),
//                "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"
//            )
//            navigator.anim(RIGHT_LEFT).startActivity(SupportActivity::class.java, bundle)
//        }

//        tvFaq.setSafetyOnclickListener {
//            // TODO change real text later
//            val bundle = SupportActivity.getBundle(
//                getString(R.string.faq),
//                "Dummy FAQ"
//            )
//            navigator.anim(RIGHT_LEFT).startActivity(SupportActivity::class.java, bundle)
//        }

        tvContact.setSafetyOnclickListener {
            Intercom.client().displayMessenger()
        }

        tvTellUs.setSafetyOnclickListener {
            navigator.openBrowser(SURVEY_URL)
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}