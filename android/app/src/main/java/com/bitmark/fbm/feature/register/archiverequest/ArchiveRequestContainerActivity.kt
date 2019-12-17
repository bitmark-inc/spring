/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest

import android.content.Intent
import android.os.Bundle
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.*
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.register.archiverequest.archiverequest.ArchiveRequestFragment
import com.bitmark.fbm.feature.register.archiverequest.credential.ArchiveRequestCredentialFragment
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.logSharedPrefError
import com.bitmark.fbm.util.ext.unexpectedAlert
import javax.inject.Inject

class ArchiveRequestContainerActivity : BaseAppCompatActivity() {

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: ArchiveRequestContainerViewModel

    @Inject
    internal lateinit var logger: EventLogger

    @Inject
    internal lateinit var dialogController: DialogController

    override fun layoutRes(): Int = R.layout.activity_archive_request_container

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.getArchiveRequestedAt()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        val isFromNotification =
            intent?.getBooleanExtra("direct_from_notification", false) ?: false
        if (isFromNotification) {
            viewModel.getArchiveRequestedAt()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.getArchiveRequestedAt.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val requestedAt = res.data()!!
                    navigator.anim(Navigator.NONE)
                        .replaceFragment(
                            R.id.layoutRoot,
                            if (requestedAt != -1L) {
                                ArchiveRequestFragment.newInstance(
                                    requestedAt = requestedAt
                                )
                            } else {
                                ArchiveRequestCredentialFragment.newInstance()
                            },
                            false
                        )
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "could not get archive requested at")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })
    }

    override fun onBackPressed() {
        val currentFragment = supportFragmentManager.findFragmentById(R.id.layoutRoot)
        if (currentFragment != null && currentFragment is BehaviorComponent && !currentFragment.onBackPressed()) {
            navigator.anim(RIGHT_LEFT).finishActivity()
        } else {
            super.onBackPressed()
        }
    }

}