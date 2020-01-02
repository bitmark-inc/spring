/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.biometricauth

import android.os.Bundle
import android.widget.CompoundButton
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.*
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

    private var blockChanging = false

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
                    logger.logSharedPrefError(res.throwable(), "get account data error")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })

        viewModel.saveAccountKeyDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    viewModel.getAccountData()
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "save account key alias error")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })
    }

    override fun onCheckedChanged(buttonView: CompoundButton?, isChecked: Boolean) {
        if (isChecked) {
            blockChanging = false
            dialogController.confirm(
                R.string.do_you_want_to_allow_to_use_biometric_auth,
                R.string.app_will_use_biometric,
                false,
                null,
                R.string.enable,
                {
                    loadAccount(
                        accountData,
                        { account ->
                            resaveAccount(
                                account,
                                true,
                                { swBiometricAuth.isChecked = false },
                                { swBiometricAuth.isChecked = false })
                        },
                        {
                            blockChanging = true
                            swBiometricAuth.isChecked = false
                        },
                        {
                            blockChanging = true
                            swBiometricAuth.isChecked = false
                        })
                },
                R.string.no_thanks,
                {
                    blockChanging = true
                    swBiometricAuth.isChecked = false
                }
            )
        } else if (!blockChanging) {
            loadAccount(
                accountData,
                { account ->
                    resaveAccount(
                        account,
                        false,
                        { swBiometricAuth.isChecked = true },
                        { swBiometricAuth.isChecked = true })
                },
                { swBiometricAuth.isChecked = true },
                { swBiometricAuth.isChecked = true })
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }

    private fun resaveAccount(
        account: Account,
        authRequired: Boolean,
        errorAction: () -> Unit,
        setupRequiredAction: () -> Unit
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
            successAction = { viewModel.saveAccountKeyData(keyAlias, authRequired) },
            setupRequiredAction = {
                setupRequiredAction()
                navigator.gotoSecuritySetting()
            },
            invalidErrorAction = { e ->
                errorAction()
                logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, e)
                dialogController.alert(e) { navigator.anim(RIGHT_LEFT).finishActivity() }
            })
    }

    private fun loadAccount(
        accountData: AccountData,
        successAction: (Account) -> Unit,
        errorAction: () -> Unit,
        setupRequiredAction: () -> Unit
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
            setupRequiredAction = {
                setupRequiredAction()
                navigator.gotoSecuritySetting()
            },
            invalidErrorAction = { e ->
                errorAction()
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.alert(e) { navigator.anim(RIGHT_LEFT).finishActivity() }
            })
    }
}