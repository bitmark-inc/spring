/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.unlink.unlink

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.showKeyBoard
import kotlinx.android.synthetic.main.fragment_unlink.*
import javax.inject.Inject


class UnlinkFragment : BaseSupportFragment() {

    companion object {
        fun newInstance() = UnlinkFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: UnlinkViewModel

    override fun layoutRes(): Int = R.layout.fragment_unlink

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        btnUnlink.setSafetyOnclickListener {
            // TODO add stuff to unlink
        }

        etPhrase.requestFocus()
        activity?.showKeyBoard()

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).popFragment()
        }
    }

    override fun onBackPressed(): Boolean {
        return navigator.anim(RIGHT_LEFT).popFragment()
    }
}