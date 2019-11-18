/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.notification

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import javax.inject.Inject

class RegisterNotificationActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: RegisterNotificationViewModel

    override fun layoutRes(): Int = R.layout.activity_register_notification

    override fun viewModel(): BaseViewModel? = viewModel
}