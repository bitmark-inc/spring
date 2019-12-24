/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import android.os.Bundle
import android.os.Handler
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.isValid
import com.bitmark.fbm.data.source.remote.api.error.UnknownException
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.FADE_IN
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.Constants
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.activity_splash.*
import java.net.URL
import javax.inject.Inject

class SplashActivity : BaseAppCompatActivity() {

    companion object {
        private const val TAG = "SplashActivity"
    }

    @Inject
    internal lateinit var viewModel: SplashViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    private val handler = Handler()

    override fun layoutRes(): Int = R.layout.activity_splash

    override fun viewModel(): BaseViewModel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.checkVersionOutOfDate()
    }

    override fun initComponents() {
        super.initComponents()

        btnGetStarted.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivityAsRoot(OnboardingActivity::class.java)
        }

        tvLogin.setSafetyOnclickListener {
            // FIXME for testing
            navigator.anim(RIGHT_LEFT).startActivityAsRoot(MainActivity::class.java)
        }
    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.checkVersionOutOfDateLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val data = res.data()!!
                    val versionOutOfDate = data.first
                    if (versionOutOfDate) {
                        // TODO change text later
                        dialogController.alert(
                            "New Update Available",
                            "Your app is out of date, please update to the latest version."
                        ) {
                            val updateUrl = data.second
                            val url = URL(updateUrl)
                            if (url.host == Constants.GOOGLE_PLAY_HOST) {
                                navigator.goToPlayStore()
                            } else {
                                navigator.openBrowser(updateUrl)
                            }
                            navigator.exitApp()
                        }
                    } else {
                        viewModel.getAccountInfo()
                    }
                }

                res.isError()   -> {
                    logger.logError(
                        Event.SPLASH_VERSION_CHECK_ERROR,
                        res.throwable() ?: UnknownException()
                    )
                    viewModel.getAccountInfo()
                }

            }
        })

        viewModel.getAccountInfoLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val data = res.data()!!
                    val accountData = data.first
                    val archiveRequestedAt = data.second
                    val archiveRequested = archiveRequestedAt != -1L
                    val loggedIn = accountData.isValid() && !archiveRequested
                    when {
                        // account already registered
                        loggedIn -> prepareData(accountData)

                        // requested archive
                        archiveRequested -> handler.postDelayed({
                            val bundle =
                                DataProcessingActivity.getBundle(
                                    getString(R.string.data_requested),
                                    getString(R.string.you_requested_your_fb_data_format).format(
                                        DateTimeUtil.millisToString(
                                            archiveRequestedAt,
                                            DateTimeUtil.DATE_FORMAT_3,
                                            DateTimeUtil.defaultTimeZone()
                                        ),
                                        DateTimeUtil.millisToString(
                                            archiveRequestedAt,
                                            DateTimeUtil.TIME_FORMAT_1,
                                            DateTimeUtil.defaultTimeZone()
                                        )
                                    ), true
                                )
                            navigator.anim(FADE_IN)
                                .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
                        }, 250)

                        else -> {
                            // do onboarding
                            showOnboarding()
                        }
                    }
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "get account info error")
                    dialogController.unexpectedAlert { navigator.exitApp() }
                }
            }
        })

        viewModel.prepareDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val dataDeleted = res.data() ?: false
                    if (dataDeleted) {
                        // do onboarding again
                        showOnboarding()
                    } else {
                        viewModel.checkDataReady()
                    }
                }

                res.isError()   -> {
                    val error = res.throwable()
                    logger.logError(
                        Event.SPLASH_PREPARE_DATA_ERROR,
                        "$TAG: prepare data error: ${error?.message ?: "unknown"}"
                    )
                    if (error is UnknownException) {
                        dialogController.unexpectedAlert { navigator.exitApp() }
                    } else {
                        dialogController.alert(error)
                    }
                }
            }
        })

        viewModel.checkDataReadyLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val dataReady = res.data() ?: false
                    handler.postDelayed({
                        if (dataReady) {
                            navigator.anim(FADE_IN)
                                .startActivityAsRoot(MainActivity::class.java)
                        } else {
//                            val bundle =
//                                DataProcessingActivity.getBundle(
//                                    getString(R.string.analyzing_data),
//                                    getString(R.string.your_fb_data_archive_has_been_successfully)
//                                )
//                            navigator.anim(FADE_IN)
//                                .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
                            navigator.anim(FADE_IN).startActivityAsRoot(MainActivity::class.java)
                        }
                    }, 250)
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "check data ready error")
                    dialogController.unexpectedAlert { navigator.exitApp() }
                }
            }
        })

    }

    private fun showOnboarding() {
        btnGetStarted.visible(true)
        tvLogin.visible(true)
    }

    private fun prepareData(accountData: AccountData) {
        loadAccount(accountData) { account ->
            viewModel.prepareData(account)
        }
    }

    private fun loadAccount(accountData: AccountData, action: (Account) -> Unit) {
        val spec =
            KeyAuthenticationSpec.Builder(this).setKeyAlias(accountData.keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(accountData.authRequired).build()
        loadAccount(
            accountData.id,
            spec,
            dialogController,
            successAction = action,
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            invalidErrorAction = { e ->
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.alert(e) { navigator.exitApp() }
            })
    }
}