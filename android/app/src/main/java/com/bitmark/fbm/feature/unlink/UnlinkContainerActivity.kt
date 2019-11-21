/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.unlink

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.BehaviorComponent
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.NONE
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.unlink.notice.UnlinkNoticeFragment
import javax.inject.Inject


class UnlinkContainerActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    override fun layoutRes(): Int = R.layout.activity_unlink_container

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        navigator.anim(NONE)
            .replaceFragment(R.id.layoutRoot, UnlinkNoticeFragment.newInstance(), false)
    }

    override fun onBackPressed() {
        val currentFragment = supportFragmentManager.findFragmentById(R.id.layoutRoot)
        if (currentFragment != null && currentFragment is BehaviorComponent) {
            currentFragment.onBackPressed()
        } else {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

    }
}