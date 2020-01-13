/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.unlink.unlink

import android.text.InputType
import android.view.inputmethod.EditorInfo
import android.webkit.CookieManager
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Observer
import com.bitmark.cryptography.error.ValidateException
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.splash.SplashActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.features.Account
import com.onesignal.OneSignal
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

        etPhrase.imeOptions = EditorInfo.IME_ACTION_DONE
        etPhrase.setRawInputType(InputType.TYPE_CLASS_TEXT)
        etPhrase.requestFocus()
        activity?.showKeyBoard()

        btnUnlink.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            try {
                val recoveryKey = etPhrase.text.toString().trim().split(" ").toTypedArray()
                Account.fromRecoveryPhrase(*recoveryKey)
                showKeyEnteringResult(true)
                viewModel.deleteData()
            } catch (e: ValidateException) {
                showKeyEnteringResult(false)
            }
        }

        etPhrase.doOnTextChanged { text, _, _, _ ->
            val phrase = text?.trim()?.split(" ")
            if (phrase != null && phrase.size == 12) {
                etPhrase.setTextColor(context!!.getColor(R.color.international_klein_blue))
            } else {
                etPhrase.setTextColor(context!!.getColor(R.color.tundora))
            }
        }

        ivBack.setOnClickListener {
            if (blocked) return@setOnClickListener
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    private fun showKeyEnteringResult(valid: Boolean) {
        if (valid) {
            tvWrongKey.gone()
            tvPlsRecheck.gone()
        } else {
            tvWrongKey.visible()
            tvPlsRecheck.visible()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.deleteDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    CookieManager.getInstance().removeAllCookies {
                        CookieManager.getInstance().flush()
                        OneSignal.setSubscription(false)
                        val snackbar = layoutRoot.createSnackbar(
                            R.string.unlink_account,
                            R.string.your_account_has_been_unlinked
                        ) {
                            navigator.anim(Navigator.NONE)
                                .startActivityAsRoot(SplashActivity::class.java)
                        }
                        snackbar.show()
                        blocked = false
                    }
                }

                res.isError() -> {
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