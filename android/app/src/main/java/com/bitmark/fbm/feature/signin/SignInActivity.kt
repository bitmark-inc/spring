/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.signin

import android.os.Handler
import android.text.InputType
import android.view.inputmethod.EditorInfo
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.ext.isServiceUnsupportedError
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.connectivity.ConnectivityHandler
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import com.onesignal.OneSignal
import kotlinx.android.synthetic.main.activity_signin.*
import javax.inject.Inject


class SignInActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: SignInViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    @Inject
    internal lateinit var connectivityHandler: ConnectivityHandler

    private var blocked = false

    private val handler = Handler()

    override fun layoutRes(): Int = R.layout.activity_signin

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        etPhrase.imeOptions = EditorInfo.IME_ACTION_DONE
        etPhrase.setRawInputType(InputType.TYPE_CLASS_TEXT)
        etPhrase.requestFocus()
        handler.postDelayed({ showKeyBoard() }, 100)

        btnSubmit.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            try {
                val phrase = etPhrase.text.toString().trim().split(" ").toTypedArray()
                val account = Account.fromRecoveryPhrase(*phrase)
                showKeyEnteringResult(true)
                val authRequired = false
                saveAccount(account, authRequired, successAction = { alias ->
                    viewModel.prepareData(account, alias, authRequired)
                }, errorAction = { e ->
                    dialogController.alert(e)
                })
            } catch (e: Throwable) {
                showKeyEnteringResult(false)
            }
        }

        etPhrase.doOnTextChanged { text, _, _, _ ->
            val phrase = text?.trim()?.split(" ")
            if (phrase != null && phrase.size == 12) {
                etPhrase.setTextColor(getColor(R.color.international_klein_blue))
            } else {
                etPhrase.setTextColor(getColor(R.color.tundora))
            }
        }

        ivBack.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
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

        viewModel.prepareDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    OneSignal.setSubscription(true)
                    progressBar.gone()
                    blocked = false
                    navigator.anim(RIGHT_LEFT).startActivityAsRoot(MainActivity::class.java)
                }
                res.isError() -> {
                    progressBar.gone()
                    blocked = false
                    logger.logError(Event.ACCOUNT_SIGNIN_ERROR, res.throwable())
                    if (!connectivityHandler.isConnected()) {
                        dialogController.showNoInternetConnection()
                    } else if (!res.throwable()!!.isServiceUnsupportedError()) {
                        dialogController.alert(R.string.error, R.string.could_not_sign_in)
                    }
                }
                res.isLoading() -> {
                    blocked = true
                    progressBar.visible()
                }
            }
        })

        viewModel.serviceUnsupportedLiveData.observe(this, Observer { url ->
            dialogController.showUpdateRequired {
                if (url.isEmpty()) {
                    navigator.goToPlayStore()
                } else {
                    navigator.goToUpdateApp(url)
                }
                navigator.exitApp()
            }
        })
    }

    private fun saveAccount(
        account: Account,
        authRequired: Boolean,
        successAction: (String) -> Unit,
        errorAction: (Throwable) -> Unit
    ) {
        val keyAlias = account.generateKeyAlias()
        val spec =
            KeyAuthenticationSpec.Builder(this)
                .setKeyAlias(keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(authRequired).build()
        this.saveAccount(
            account,
            spec,
            dialogController,
            successAction = { successAction(keyAlias) },
            setupRequiredAction = {
                navigator.gotoSecuritySetting()
            },
            invalidErrorAction = { e ->
                errorAction(e ?: IllegalAccessException("unknown error"))
                logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, e)
            })
    }

    override fun onBackPressed() {
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}