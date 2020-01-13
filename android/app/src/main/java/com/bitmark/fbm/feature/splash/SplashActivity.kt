/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.splash

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.text.Spannable
import android.text.SpannableString
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.text.style.StyleSpan
import android.view.View
import androidx.lifecycle.Observer
import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.R
import com.bitmark.fbm.data.ext.isServiceUnsupportedError
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.isValid
import com.bitmark.fbm.data.source.remote.api.error.UnknownException
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.BOTTOM_UP
import com.bitmark.fbm.feature.Navigator.Companion.FADE_IN
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingActivity
import com.bitmark.fbm.feature.register.onboarding.OnboardingActivity
import com.bitmark.fbm.feature.signin.SignInActivity
import com.bitmark.fbm.feature.whatsnew.WhatsNewActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.activity_splash.*
import javax.inject.Inject

class SplashActivity : BaseAppCompatActivity() {

    companion object {
        private const val TAG = "SplashActivity"

        private const val WHATS_NEW_REQ_CODE = 0xA7
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

        val tosAndPpString = getString(R.string.by_continuing)
        val spannableString = SpannableString(tosAndPpString)
        val tosString = getString(R.string.term_of_service)
        val ppString = getString(R.string.privacy_policy)

        var startIndex = tosAndPpString.indexOf(tosString)
        var endIndex = startIndex + tosString.length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    // TODO go to term of service
                }

            }, startIndex,
            endIndex,
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            StyleSpan(Typeface.ITALIC),
            startIndex,
            endIndex,
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE
        )

        startIndex = tosAndPpString.indexOf(ppString)
        endIndex = startIndex + ppString.length
        spannableString.setSpan(
            object : ClickableSpan() {
                override fun onClick(widget: View) {
                    // TODO go to privacy policy
                }

            }, startIndex,
            endIndex,
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE
        )
        spannableString.setSpan(
            StyleSpan(Typeface.ITALIC),
            startIndex,
            endIndex,
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE
        )

        tvToSandPP.text = spannableString
        tvToSandPP.movementMethod = LinkMovementMethod.getInstance()
        tvToSandPP.setLinkTextColor(getColor(R.color.white))
        tvToSandPP.highlightColor = Color.TRANSPARENT

        btnGetStarted.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(OnboardingActivity::class.java)
        }

        tvLogin.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).startActivity(SignInActivity::class.java)
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
                        dialogController.showUpdateRequired {
                            val updateUrl = data.second
                            navigator.goToUpdateApp(updateUrl)
                            navigator.exitApp()
                        }
                    } else {
                        viewModel.checkFirstTimeEnterNewVersion(BuildConfig.VERSION_CODE)
                    }
                }

                res.isError() -> {
                    logger.logError(
                        Event.SPLASH_VERSION_CHECK_ERROR,
                        res.throwable() ?: UnknownException()
                    )
                    viewModel.checkFirstTimeEnterNewVersion(BuildConfig.VERSION_CODE)
                }

            }
        })

        viewModel.checkFirstTimeEnterNewVersionLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val firstTimeEnter = res.data() ?: false
                    if (firstTimeEnter) {
                        val bundle = WhatsNewActivity.getBundle(false)
                        navigator.anim(BOTTOM_UP).startActivityForResult(
                            WhatsNewActivity::class.java,
                            WHATS_NEW_REQ_CODE,
                            bundle
                        )
                    } else {
                        viewModel.getAccountInfo()
                    }
                }

                res.isError() -> {
                    logger.logSharedPrefError(
                        res.throwable(),
                        "check first time enter new version error"
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
                            val msg =
                                "${getString(R.string.we_are_waiting_for_fb_1)}\n\n${getString(R.string.you_requested_your_fb_archive_format).format(
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
                                )}"
                            val bundle = DataProcessingActivity.getBundle(
                                getString(R.string.data_requested),
                                msg,
                                true
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

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "get account info error")
                    dialogController.unexpectedAlert { navigator.exitApp() }
                }
            }
        })

        viewModel.prepareDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val invalidArchives = res.data() ?: false
                    if (invalidArchives) {
                        showDataAnalyzing()
                    } else {
                        viewModel.checkDataReady()
                    }
                }

                res.isError() -> {
                    val error = res.throwable()!!
                    logger.logError(
                        Event.SPLASH_PREPARE_DATA_ERROR,
                        "$TAG: prepare data error: ${error.message ?: "unknown"}"
                    )
                    if (!error.isServiceUnsupportedError()) {
                        if (error is UnknownException) {
                            dialogController.unexpectedAlert { navigator.exitApp() }
                        } else {
                            dialogController.alert(error) { navigator.exitApp() }
                        }
                    }
                }
            }
        })

        viewModel.checkDataReadyLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val dataReady = res.data()!!.first
                    val categoryReady = res.data()!!.second

                    handler.postDelayed({
                        if (dataReady) {
                            if (categoryReady) {
                                navigator.anim(FADE_IN)
                                    .startActivityAsRoot(MainActivity::class.java)
                            } else {
                                val bundle = ArchiveRequestContainerActivity.getBundle(true)
                                navigator.anim(FADE_IN)
                                    .startActivityAsRoot(
                                        ArchiveRequestContainerActivity::class.java,
                                        bundle
                                    )
                            }
                        } else {
                            showDataAnalyzing()
                        }
                    }, 250)
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "check data ready error")
                    dialogController.unexpectedAlert { navigator.exitApp() }
                }
            }
        })

    }

    private fun showDataAnalyzing() {
        val bundle =
            DataProcessingActivity.getBundle(
                getString(R.string.processing_data),
                getString(R.string.your_fb_data_archive_has_been_successfully)
            )
        navigator.anim(FADE_IN)
            .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
    }

    private fun showOnboarding() {
        tvToSandPP.visible(true)
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
            canceledAction = {
                dialogController.showAuthRequired {
                    loadAccount(accountData, action)
                }
            },
            invalidErrorAction = { e ->
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.alert(e) { navigator.exitApp() }
            })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK && requestCode == WHATS_NEW_REQ_CODE) {
            viewModel.getAccountInfo()
        }
    }
}