/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.archiverequest

import android.text.SpannableString
import android.text.style.UnderlineSpan
import androidx.lifecycle.Observer
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import com.bitmark.synergy.feature.DialogController
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.synergy.feature.register.notification.RegisterNotificationActivity
import com.bitmark.synergy.logging.Event
import com.bitmark.synergy.logging.EventLogger
import com.bitmark.synergy.logging.Tracer
import com.bitmark.synergy.util.ext.gone
import com.bitmark.synergy.util.ext.setSafetyOnclickListener
import com.bitmark.synergy.util.ext.visible
import kotlinx.android.synthetic.main.activity_archive_request.*
import kotlinx.android.synthetic.main.activity_onboarding.ivBack
import javax.inject.Inject

class ArchiveRequestActivity : BaseAppCompatActivity() {

    companion object {
        private const val TAG = "ArchiveRequestActivity"
    }

    @Inject
    internal lateinit var viewModel: ArchiveRequestViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private var blocked = false

    override fun layoutRes(): Int = R.layout.activity_archive_request

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        val spannableContent = getString(R.string.prefer_to_do_this_manually)
        val spannableString = SpannableString(spannableContent)
        spannableString.setSpan(
            UnderlineSpan(), 0, spannableContent.length,
            SpannableString.SPAN_INCLUSIVE_EXCLUSIVE
        )
        tvUploadManually.text = spannableString

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT)
                .finishActivity()
        }

        tvUploadManually.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
        }

        tvAuthorize.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            authorize()
        }
    }

    private fun authorize() {
        val fbId = etId.text?.trim()?.toString() ?: ""
        val fbPassword = etPassword.text?.trim()?.toString() ?: ""
        if (fbId.isEmpty() || fbPassword.isEmpty()) return
        val account = Account()
        saveAccount(account) { alias ->
            val requester = account.accountNumber
            val timestamp = System.currentTimeMillis().toString()
            val signature = HEX.encode(account.sign(RAW.decode(timestamp)))
            viewModel.registerAccount(
                requester,
                timestamp,
                signature,
                fbId,
                fbPassword,
                alias
            )
        }
    }

    private fun saveAccount(
        account: Account,
        successAction: (String) -> Unit
    ) {
        val keyAlias =
            "%s.%d.encryption_key".format(
                account.accountNumber,
                System.currentTimeMillis()
            )
        val accountAuthBuilder = KeyAuthenticationSpec.Builder(this)
            .setKeyAlias(keyAlias)
            .setAuthenticationRequired(false)

        account.saveToKeyStore(
            this,
            accountAuthBuilder.build(),
            object : Callback0 {
                override fun onSuccess() {
                    successAction(keyAlias)
                }

                override fun onError(throwable: Throwable?) {
                    Tracer.ERROR.log(TAG, "save account failed: ${throwable?.message ?: "unknown"}")
                    logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, throwable)
                    dialogController.alert(
                        getString(R.string.error),
                        throwable?.message ?: getString(R.string.unexpected_error)
                    )
                }

            })
    }

    override fun observe() {
        super.observe()

        viewModel.registerAccountLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    navigator.anim(RIGHT_LEFT)
                        .startActivityAsRoot(RegisterNotificationActivity::class.java)
                    blocked = false
                }

                res.isError() -> {
                    progressBar.gone()
                    dialogController.alert(R.string.error, R.string.could_not_register_account)
                    blocked = false
                }

                res.isLoading() -> {
                    progressBar.visible()
                    blocked = true
                }
            }
        })
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT)
            .finishActivity()
    }

}