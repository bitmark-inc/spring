/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.archiverequest

import android.text.SpannableString
import android.text.style.UnderlineSpan
import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.synergy.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_archive_request.tvUploadManually
import kotlinx.android.synthetic.main.activity_onboarding.ivBack
import javax.inject.Inject

class ArchiveRequestActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: ArchiveRequestViewModel

    @Inject
    internal lateinit var navigator: Navigator

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

        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT)
                .finishActivity()
    }

}