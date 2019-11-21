/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.support

import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import kotlinx.android.synthetic.main.activity_support.*
import javax.inject.Inject


class SupportActivity : BaseAppCompatActivity() {

    companion object {
        private val TITLE = "title"

        private val MESSAGE = "msg"

        fun getBundle(title: String, message: String): Bundle {
            val bundle = Bundle()
            bundle.putString(TITLE, title)
            bundle.putString(MESSAGE, message)
            return bundle
        }
    }

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_support

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        val bundle = intent?.extras ?: throw IllegalArgumentException("missing intent extras")
        val title = bundle.getString(TITLE)
        val message = bundle.getString(MESSAGE)
        tvTitle.text = title
        tvMsg.text = message

        tvMsg.movementMethod = ScrollingMovementMethod()

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}