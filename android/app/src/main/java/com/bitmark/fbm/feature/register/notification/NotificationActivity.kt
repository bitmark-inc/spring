/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.notification

import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.logSharedPrefError
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.unexpectedAlert
import kotlinx.android.synthetic.main.activity_notification.*
import javax.inject.Inject


class NotificationActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: NotificationViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var logger: EventLogger

    @Inject
    internal lateinit var dialogController: DialogController

    override fun layoutRes(): Int = R.layout.activity_notification

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        ivBack.setOnClickListener { navigator.anim(RIGHT_LEFT).finishActivity() }

        btnContinue.setSafetyOnclickListener {
            viewModel.setNotificationEnabled(true)
        }

        btnSkip.setSafetyOnclickListener {
            viewModel.setNotificationEnabled(false)
        }
    }

    override fun observe() {
        super.observe()

        viewModel.setNotificationEnabledLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    navigator.anim(RIGHT_LEFT)
                        .startActivity(ArchiveRequestContainerActivity::class.java)
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "could not set notification enabled")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })
    }

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }
}