/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.register.archiverequest

import com.bitmark.synergy.R
import com.bitmark.synergy.feature.BaseAppCompatActivity
import com.bitmark.synergy.feature.BaseViewModel
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.RIGHT_LEFT
import javax.inject.Inject

class ArchiveRequestActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var viewModel: ArchiveRequestViewModel

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_archive_request

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onBackPressed() {
        super.onBackPressed()
        navigator.anim(RIGHT_LEFT).finishActivity()
    }

}