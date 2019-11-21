/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.recovery.notice

import android.text.method.ScrollingMovementMethod
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.recovery.access.RecoveryAccessFragment
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
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

    override fun layoutRes(): Int = R.layout.fragment_recovery_notice

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        tvMsg.movementMethod = ScrollingMovementMethod()

        btnWriteDownKey.setSafetyOnclickListener {
            // TODO change real logic later
            val words =
                "abandon ability able about above absent absorb abstract absurd abuse access accident".split(
                    " "
                ).toList()
            navigator.anim(RIGHT_LEFT)
                .replaceFragment(R.id.layoutRoot, RecoveryAccessFragment.newInstance(words))
        }

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun onBackPressed(): Boolean {
        navigator.anim(RIGHT_LEFT).finishActivity()
        return true
    }

}