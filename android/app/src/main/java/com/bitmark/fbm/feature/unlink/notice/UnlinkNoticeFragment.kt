/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.unlink.notice

import android.text.method.ScrollingMovementMethod
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.unlink.unlink.UnlinkFragment
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.fragment_unlink_notice.*
import javax.inject.Inject


class UnlinkNoticeFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = UnlinkNoticeFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.fragment_unlink_notice

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        tvMsg.movementMethod = ScrollingMovementMethod()

        btnContinue.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT)
                .replaceFragment(R.id.layoutRoot, UnlinkFragment.newInstance(), true)
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