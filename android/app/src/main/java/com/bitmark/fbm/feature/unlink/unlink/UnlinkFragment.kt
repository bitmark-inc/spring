/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.unlink.unlink

import androidx.lifecycle.Observer
import com.bitmark.cryptography.error.ValidateException
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.NONE
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.splash.SplashActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.createSnackbar
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.showKeyBoard
import com.bitmark.fbm.util.ext.unexpectedAlert
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.fragment_unlink.*
import javax.inject.Inject


class UnlinkFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = UnlinkFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: UnlinkViewModel

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private var blocked = false

    override fun layoutRes(): Int = R.layout.fragment_unlink

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        btnUnlink.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            try {
                val recoveryKey = etPhrase.text.toString().trim().split(" ").toTypedArray()
                Account.fromRecoveryPhrase(*recoveryKey)
                viewModel.deleteData()
            } catch (e: ValidateException) {
                // TODO change text later
                dialogController.alert("Error", "Invalid recovery key")
            }
        }

        etPhrase.requestFocus()
        activity?.showKeyBoard()

        ivBack.setOnClickListener {
            if (blocked) return@setOnClickListener
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.deleteDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val snackbar = layoutRoot.createSnackbar(
                        R.string.unlink_account,
                        R.string.your_account_has_been_unlinked
                    ) {
                        navigator.anim(NONE).startActivityAsRoot(SplashActivity::class.java)
                    }
                    snackbar.show()
                    blocked = false
                }

                res.isError()   -> {
                    logger.logError(Event.ACCOUNT_UNLINK_ERROR, res.throwable())
                    dialogController.unexpectedAlert { navigator.exitApp() }
                    blocked = false
                }

                res.isLoading() -> {
                    blocked = true
                }
            }
        })
    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }
}