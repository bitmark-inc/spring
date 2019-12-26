/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.lens

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.fragment_lens_container.*
import javax.inject.Inject


class LensContainerFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = LensContainerFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.fragment_lens_container

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        ivAccount.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }
    }
}