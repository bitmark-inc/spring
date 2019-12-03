/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.dataprocessing

import android.os.Bundle
import android.view.View
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.activity_data_processing.*
import kotlinx.android.synthetic.main.fragment_archive_request_credential.tvTitle
import javax.inject.Inject

class DataProcessingActivity : BaseAppCompatActivity() {

    companion object {

        private const val TITLE = "title"

        private const val MESSAGE = "message"

        private const val SHOW_ACTION_BUTTON = "show_action_button"

        fun getBundle(title: String, message: String, showActionButton: Boolean = false): Bundle {
            val bundle = Bundle()
            bundle.putString(TITLE, title)
            bundle.putString(MESSAGE, message)
            bundle.putBoolean(SHOW_ACTION_BUTTON, showActionButton)
            return bundle
        }

    }

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_data_processing

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        require(intent?.extras?.containsKey(TITLE) == true && intent?.extras?.containsKey(MESSAGE) == true) { "missing required TITLE or MESSAGE bundle params" }

        val title = intent?.extras?.getString(TITLE)
        val msg = intent?.extras?.getString(MESSAGE)
        val showActionButton = intent?.extras?.getBoolean(SHOW_ACTION_BUTTON) ?: false

        tvTitle.text = title
        tvMsg.text = msg
        btnCheckNow.visibility = if (showActionButton) View.VISIBLE else View.INVISIBLE

        btnCheckNow.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT)
                .startActivityAsRoot(ArchiveRequestContainerActivity::class.java)
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}