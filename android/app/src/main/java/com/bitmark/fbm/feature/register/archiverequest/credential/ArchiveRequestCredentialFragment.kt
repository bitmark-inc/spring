/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.credential

import android.content.Context
import android.os.Bundle
import android.os.Handler
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.CredentialData
import com.bitmark.fbm.data.model.save
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.archiverequest.archiverequest.ArchiveRequestFragment
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.ext.*
import kotlinx.android.synthetic.main.fragment_archive_request_credential.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.inject.Inject


class ArchiveRequestCredentialFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "ArchiveRequestCredentialFragment"

        private const val ACCOUNT_REGISTERED = "account_registered"

        fun newInstance(accountRegistered: Boolean = false): ArchiveRequestCredentialFragment {
            val fragment = ArchiveRequestCredentialFragment()
            val bundle = Bundle()
            bundle.putBoolean(ACCOUNT_REGISTERED, accountRegistered)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var viewModel: ArchiveRequestCredentialViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private val handler = Handler()

    private lateinit var executor: ExecutorService

    private var accountRegistered = false

    override fun layoutRes(): Int = R.layout.fragment_archive_request_credential

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onAttach(context: Context) {
        super.onAttach(context)

        accountRegistered = arguments?.getBoolean(ACCOUNT_REGISTERED) ?: false
    }

    override fun initComponents() {
        super.initComponents()

        executor = Executors.newSingleThreadExecutor()

        if (accountRegistered) {
            ivBack.gone()
        } else {
            ivBack.visible()
        }

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

        btnAutomate.setSafetyOnclickListener {
            if (accountRegistered) {
                val fbId = etId.text.toString().trim()
                viewModel.verifyFbAccount(fbId)
            } else {
                saveCredential({
                    navigator.anim(RIGHT_LEFT).replaceFragment(
                        R.id.layoutRoot,
                        ArchiveRequestFragment.newInstance(accountRegistered = accountRegistered)
                    )
                }, {
                    dialogController.unexpectedAlert {
                        navigator.anim(RIGHT_LEFT).finishActivity()
                    }
                })
            }

        }

        etId.doOnTextChanged { _, _, _, _ ->
            btnAutomate.isEnabled = validCredential()
        }

        etPassword.doOnTextChanged { _, _, _, _ ->
            btnAutomate.isEnabled = validCredential()
        }


        etId.requestFocus()
        handler.postDelayed({
            activity?.showKeyBoard()
        }, 100)
    }

    private fun validCredential() =
        etId.text.toString().trim().isNotBlank() && etPassword.text.toString().trim().isNotBlank()

    override fun deinitComponents() {
        executor.shutdown()
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.verifyFbAccountLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val verified = res.data()!!
                    if (verified) {
                        saveCredential({
                            navigator.anim(RIGHT_LEFT).replaceFragment(
                                R.id.layoutRoot,
                                ArchiveRequestFragment.newInstance(accountRegistered = accountRegistered)
                            )
                        }, {
                            dialogController.unexpectedAlert {
                                navigator.anim(RIGHT_LEFT).finishActivity()
                            }
                        })
                    } else {
                        dialogController.alert(
                            R.string.accounts_dont_match,
                            R.string.you_must_use_the_fb,
                            R.string.try_again
                        )
                    }
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "verifyFbAccount error")
                    dialogController.unexpectedAlert {
                        navigator.anim(RIGHT_LEFT).finishActivity()
                    }
                }
            }
        })

    }

    private fun saveCredential(success: () -> Unit, error: () -> Unit) {
        val fbId = etId.text.toString().trim()
        val fbPassword = etPassword.text.toString().trim()
        val credential = CredentialData(fbId, fbPassword)
        credential.save(activity!!, executor, {
            success()
        }, { e ->
            val errMsg = e?.message ?: "could not save credential"
            Tracer.ERROR.log(TAG, errMsg)
            logger.logError(
                Event.ACCOUNT_SAVE_FB_CREDENTIAL_ERROR,
                IllegalAccessException(errMsg)
            )
            error()
        })
    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }
}