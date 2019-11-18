/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.notification

import android.os.Bundle
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.activity_register_notification.*
import javax.inject.Inject

class RegisterNotificationActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: RegisterNotificationViewModel

    @Inject
    internal lateinit var dialogController: DialogController

    private var blocked = false

    override fun layoutRes(): Int = R.layout.activity_register_notification

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.checkNotificationServiceRegistration()
    }

    override fun initComponents() {
        super.initComponents()

        btnNotifyMe.setOnClickListener {
            if (blocked) return@setOnClickListener
            dialogController.confirm(
                R.string.enable_push_notification,
                R.string.allow_spring_to_send_you,
                false,
                R.string.enable,
                {
                    viewModel.registerNotification()
                },
                R.string.no_thanks
            )
        }
    }

    override fun observe() {
        super.observe()

        viewModel.registerNotificationLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    btnNotifyMe.gone()
                    tvNotice.visible()
                    blocked = false
                }

                res.isError()   -> {
                    dialogController.alert(R.string.error, R.string.could_not_setup_notification)
                    blocked = false
                }

                res.isLoading() -> {
                    blocked = true
                }
            }
        })

        viewModel.checkNotificationServiceRegistrationLiveData.asLiveData()
            .observe(this, Observer { res ->
                when {
                    res.isSuccess() -> {
                        val registered = res.data() ?: false
                        if (registered) {
                            btnNotifyMe.gone()
                            tvNotice.visible()
                        } else {
                            btnNotifyMe.visible()
                            tvNotice.gone()
                        }
                    }

                    res.isError()   -> {
                        // assume no error here
                    }
                }
            })
    }
}