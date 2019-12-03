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
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.archiverequest.archiverequest.ArchiveRequestFragment
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.showKeyBoard
import kotlinx.android.synthetic.main.fragment_archive_request_credential.*
import javax.inject.Inject


class ArchiveRequestCredentialFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = ArchiveRequestCredentialFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: ArchiveRequestCredentialViewModel

    private val handler = Handler()

    override fun layoutRes(): Int = R.layout.fragment_archive_request_credential

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

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
            viewModel.saveFbCredential(fbId, fbPassword)
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
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.saveFbCredentialLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    navigator.anim(RIGHT_LEFT).replaceFragment(
                        R.id.layoutRoot,
                        ArchiveRequestFragment.newInstance()
                    )
                }
            }
        })
    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }
}