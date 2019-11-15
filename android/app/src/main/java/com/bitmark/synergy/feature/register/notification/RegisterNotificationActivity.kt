/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.notification

import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import javax.inject.Inject

class RegisterNotificationActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: RegisterNotificationViewModel

    override fun layoutRes(): Int = R.layout.activity_register_notification

    override fun viewModel(): BaseViewModel? = viewModel
}