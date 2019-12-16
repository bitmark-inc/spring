/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.recovery.notice

import android.text.method.ScrollingMovementMethod
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.recovery.access.RecoveryAccessFragment
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.gotoSecuritySetting
import com.bitmark.fbm.util.ext.loadAccount
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.fragment_recovery_notice.*
import javax.inject.Inject


class RecoveryNoticeFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = RecoveryNoticeFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: RecoveryNoticeViewModel

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    override fun layoutRes(): Int = R.layout.fragment_recovery_notice

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        tvMsg.movementMethod = ScrollingMovementMethod()

        btnWriteDownKey.setSafetyOnclickListener {
            viewModel.getAccountData()
        }

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.getAccountDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val accountData = res.data()!!
                    loadAccount(accountData) { account ->
                        navigator.anim(RIGHT_LEFT)
                            .replaceFragment(
                                R.id.layoutRoot,
                                RecoveryAccessFragment.newInstance(account.recoveryPhrase.mnemonicWords.toList())
                            )
                    }
                }

                res.isError()   -> {
                    logger.logError(
                        Event.SHARE_PREF_ERROR,
                        "could not get account data: ${res.throwable() ?: "unknown"}"
                    )
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    ) { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })

    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }

    private fun loadAccount(accountData: AccountData, action: (Account) -> Unit) {
        val spec =
            KeyAuthenticationSpec.Builder(context).setKeyAlias(accountData.keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(accountData.authRequired).build()
        activity?.loadAccount(
            accountData.id,
            spec,
            dialogController,
            successAction = action,
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            invalidErrorAction = { e ->
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.alert(
                    R.string.error,
                    R.string.unexpected_error
                ) { navigator.exitApp() }
            })
    }

}