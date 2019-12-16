/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.auth

import android.os.Bundle
import android.widget.CompoundButton
import androidx.lifecycle.Observer
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.generateKeyAlias
import com.bitmark.fbm.util.ext.gotoSecuritySetting
import com.bitmark.fbm.util.ext.loadAccount
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.activity_authentication.*
import javax.inject.Inject


class BiometricAuthActivity : BaseAppCompatActivity(), CompoundButton.OnCheckedChangeListener {

    @Inject
    internal lateinit var viewModel: BiometricAuthViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private lateinit var accountData: AccountData

    override fun layoutRes(): Int = R.layout.activity_authentication

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.getAccountData()
    }

    override fun initComponents() {
        super.initComponents()

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.getAccountDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    accountData = res.data()!!
                    swBiometricAuth.isChecked = accountData.authRequired
                    swBiometricAuth.setOnCheckedChangeListener(this)
                }

                res.isError()   -> {
                    logger.logError(
                        Event.SHARE_PREF_ERROR,
                        "get account data error: ${res.throwable()?.message ?: "unknown"}"
                    )
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    ) { navigator.finishActivity() }
                }
            }
        })

        viewModel.saveAccountKeyDataLiveData.asLiveData().observe(this, Observer { res ->
            when {

                res.isError() -> {
                    logger.logError(
                        Event.SHARE_PREF_ERROR,
                        "save account key alias error: ${res.throwable()?.message ?: "unknown"}"
                    )
                    dialogController.alert(
                        getString(R.string.error),
                        res?.throwable()?.message ?: getString(R.string.unexpected_error)
                    )
                }
            }
        })
    }

    override fun onCheckedChanged(buttonView: CompoundButton?, isChecked: Boolean) {
        if (isChecked) {
            dialogController.confirm(
                R.string.do_you_want_to_allow_to_use_biometric_auth,
                R.string.app_will_use_biometric,
                false,
                R.string.enable,
                {
                    loadAccount(
                        accountData,
                        { account ->
                            resaveAccount(account, true) {
                                swBiometricAuth.isChecked = false
                            }
                        },
                        { swBiometricAuth.isChecked = false })
                },
                R.string.no_thanks,
                {
                    swBiometricAuth.isChecked = false
                }
            )
        } else {
            loadAccount(
                accountData,
                { account ->
                    resaveAccount(account, false) {
                        swBiometricAuth.isChecked = true
                    }
                },
                { swBiometricAuth.isChecked = true })
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }

    private fun resaveAccount(account: Account, authRequired: Boolean, errorAction: () -> Unit) {
        val keyAlias = account.generateKeyAlias()
        val spec =
            KeyAuthenticationSpec.Builder(this)
                .setKeyAlias(keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(authRequired).build()
        saveAccount(
            account,
            spec,
            { viewModel.saveAccountKeyData(keyAlias, authRequired) },
            errorAction
        )
    }

    private fun loadAccount(
        accountData: AccountData,
        successAction: (Account) -> Unit,
        errorAction: () -> Unit
    ) {
        val spec =
            KeyAuthenticationSpec.Builder(this).setKeyAlias(accountData.keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(accountData.authRequired).build()
        loadAccount(
            accountData.id,
            spec,
            dialogController,
            successAction = successAction,
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            invalidErrorAction = { e ->
                errorAction()
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.alert(
                    R.string.error,
                    R.string.unexpected_error
                )
            })
    }

    private fun saveAccount(
        account: Account,
        keySpec: KeyAuthenticationSpec,
        successAction: () -> Unit,
        errorAction: () -> Unit
    ) {
        account.saveToKeyStore(
            this,
            keySpec,
            object : Callback0 {
                override fun onSuccess() {
                    successAction()
                }

                override fun onError(throwable: Throwable?) {
                    errorAction()
                    logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, throwable)
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    )
                }

            })
    }
}