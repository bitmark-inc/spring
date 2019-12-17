/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.credential

import android.os.Handler
import android.text.SpannableString
import android.text.style.UnderlineSpan
import com.bitmark.apiservice.utils.callback.Callback0
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
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.showKeyBoard
import com.bitmark.fbm.util.ext.unexpectedAlert
import kotlinx.android.synthetic.main.fragment_archive_request_credential.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.inject.Inject


class ArchiveRequestCredentialFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "ArchiveRequestCredentialFragment"

        fun newInstance() = ArchiveRequestCredentialFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private val handler = Handler()

    private lateinit var executor: ExecutorService

    override fun layoutRes(): Int = R.layout.fragment_archive_request_credential

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        executor = Executors.newSingleThreadExecutor()

        val spannableContent = getString(R.string.prefer_to_do_this_manually)
        val spannableString = SpannableString(spannableContent)
        spannableString.setSpan(
            UnderlineSpan(),
            0,
            spannableContent.length,
            SpannableString.SPAN_INCLUSIVE_EXCLUSIVE
        )
        tvManual.text = spannableString

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

        tvAutomate.setSafetyOnclickListener {
            val fbId = etId.text.toString().trim()
            val fbPassword = etPassword.text.toString().trim()
            if (fbId.isBlank() || fbPassword.isBlank()) return@setSafetyOnclickListener
            val credential = CredentialData(fbId, fbPassword)
            credential.save(activity!!, executor, object : Callback0 {
                override fun onSuccess() {
                    navigator.anim(RIGHT_LEFT).replaceFragment(
                        R.id.layoutRoot,
                        ArchiveRequestFragment.newInstance()
                    )
                }

                override fun onError(throwable: Throwable?) {
                    val errMsg = throwable?.message ?: "could not save credential"
                    Tracer.ERROR.log(TAG, errMsg)
                    logger.logError(
                        Event.ACCOUNT_SAVE_FB_CREDENTIAL_ERROR,
                        IllegalAccessException(errMsg)
                    )
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }

            })
        }

        tvManual.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).replaceFragment(
                R.id.layoutRoot,
                ArchiveRequestFragment.newInstance()
            )
        }

        etId.requestFocus()
        handler.postDelayed({
            activity?.showKeyBoard()
        }, 100)
    }

    override fun deinitComponents() {
        executor.shutdown()
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }
}