/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.register.archiverequest.archiverequest

import android.annotation.SuppressLint
import android.app.AlarmManager
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.View
import android.webkit.*
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.isServiceUnsupportedError
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.*
import com.bitmark.fbm.data.source.remote.api.error.UnknownException
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.connectivity.ConnectivityHandler
import com.bitmark.fbm.feature.main.MainActivity
import com.bitmark.fbm.feature.notification.buildSimpleNotificationBundle
import com.bitmark.fbm.feature.notification.cancelNotification
import com.bitmark.fbm.feature.notification.pushDailyRepeatingNotification
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.callback.Action1
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import com.onesignal.OneSignal
import kotlinx.android.synthetic.main.fragment_archive_request.*
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.inject.Inject

class ArchiveRequestFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "ArchiveRequestFragment"

        private const val ARCHIVE_DOWNLOAD_HOST = "bigzipfiles.facebook.com"

        private const val FB_ENDPOINT = "https://m.facebook.com"

        private const val ARCHIVE_REQUESTED_AT = "archive_requested_at"

        private const val ACCOUNT_REGISTERED = "account_registered"

        private const val NOTIFICATION_ID = 0xA1

        private const val MAX_RELOAD_COUNT = 5

        private val EXPECTED_PAGES = mapOf(
            Page.Name.LOGIN to listOf(
                Page.Name.SAVE_DEVICE,
                Page.Name.ACCOUNT_PICKING,
                Page.Name.NEW_FEED
            ),
            Page.Name.SAVE_DEVICE to listOf(Page.Name.NEW_FEED),
            Page.Name.NEW_FEED to listOf(Page.Name.SETTINGS),
            Page.Name.SETTINGS to listOf(Page.Name.ARCHIVE, Page.Name.ADS_PREF),
            Page.Name.ADS_PREF to listOf(Page.Name.DEMOGRAPHIC),
            Page.Name.DEMOGRAPHIC to listOf(Page.Name.BEHAVIORS)
        )

        fun newInstance(
            requestedAt: Long = -1L,
            accountRegistered: Boolean = false
        ): ArchiveRequestFragment {
            val fragment = ArchiveRequestFragment()
            val bundle = Bundle()
            bundle.putLong(ARCHIVE_REQUESTED_AT, requestedAt)
            bundle.putBoolean(ACCOUNT_REGISTERED, accountRegistered)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: ArchiveRequestViewModel

    @Inject
    internal lateinit var dialogController: DialogController

    @Inject
    internal lateinit var logger: EventLogger

    @Inject
    internal lateinit var connectivityHandler: ConnectivityHandler

    private var blocked = false

    // flag to determine already sent archive download request
    private var registered = false

    private lateinit var executor: ExecutorService

    private val handler = Handler()

    private var fbCredential: CredentialData? = null

    private var archiveRequestedAt = -1L

    private var expectedPage: List<Page.Name>? = null

    private var lastUrl = ""

    private var reloadCount = 0

    private var checkLoginFailedLooperStopped = false

    private lateinit var downloadArchiveCredential: DownloadArchiveCredential

    override fun layoutRes(): Int = R.layout.fragment_archive_request

    override fun viewModel(): BaseViewModel? = null

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        archiveRequestedAt = arguments?.getLong(ARCHIVE_REQUESTED_AT) ?: -1L
        registered = arguments?.getBoolean(ACCOUNT_REGISTERED) ?: false

        viewModel.prepareData()
    }

    override fun initComponents() {
        super.initComponents()
        executor = Executors.newSingleThreadExecutor()

        wv.settings.cacheMode = WebSettings.LOAD_NO_CACHE
        wv.settings.setAppCacheEnabled(false)
    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        executor.shutdown()
        wv.webChromeClient = null
        wv.webViewClient = null
        wv.setDownloadListener(null)
        wv.destroy()
        super.deinitComponents()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun loadPage(wv: WebView, url: String, script: AutomationScriptData) {
        wv.settings.javaScriptEnabled = true
        val webChromeClient = object : WebChromeClient() {

            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                super.onProgressChanged(view, newProgress)
                if (newProgress >= 100) {
                    if (lastUrl == wv.url) return
                    lastUrl = wv.url
                    handlePageLoaded(wv, script, registered)
                }
            }
        }

        val webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                wv.loadUrl(url)
                return true
            }
        }
        wv.webViewClient = webViewClient
        wv.webChromeClient = webChromeClient

        wv.setDownloadListener { urlString, _, _, _, _ ->
            try {
                val host = URL(urlString).host
                if (host == ARCHIVE_DOWNLOAD_HOST && !blocked) {
                    val cookie = CookieManager.getInstance().getCookie(urlString)
                    downloadArchiveCredential = DownloadArchiveCredential(
                        urlString,
                        cookie
                    )
                    viewModel.getExistingAccountData()
                }
            } catch (e: Throwable) {
                Tracer.ERROR.log(
                    TAG,
                    "setDownloadListener failed with error: ${e.message ?: "unknown"}"
                )
            }
        }

        wv.loadUrl(url)

        showAutomatingState()
    }

    private fun handlePageLoaded(wv: WebView, script: AutomationScriptData, registered: Boolean) {
        wv.detectPage(script.pages, tag = TAG, logger = logger) { name ->

            val unexpectedPageDetected = expectedPage != null && !expectedPage!!.contains(name)
            if (unexpectedPageDetected) {
                handleUnexpectedPageDetected(wv)
            } else {
                showAutomatingState()
                reloadCount = 0 // reset after detect expected page
                expectedPage = EXPECTED_PAGES[name]

                if (registered) {
                    automateCategoriesFetching(wv, name, script)
                } else {
                    automateAccountRegister(wv, name, script)
                }
            }

            // stop checking login failed looper after leaving LOGIN page
            if (name != Page.Name.LOGIN) {
                checkLoginFailedLooperStopped = true
            }
        }
    }

    private fun automateCategoriesFetching(
        wv: WebView,
        pageName: Page.Name,
        script: AutomationScriptData
    ) {


        when (pageName) {
            Page.Name.LOGIN -> {
                startCheckLoginFailedLooper(wv, script)
                wv.evaluateJs(
                    script.getLoginScript(fbCredential!!.id, fbCredential!!.password)
                        ?: return
                )
            }
            Page.Name.SAVE_DEVICE -> {
                wv.evaluateJs(script.getSaveDeviceOkScript())
            }
            Page.Name.NEW_FEED -> {
                wv.evaluateJs(script.getNewFeedGoToSettingPageScript())
            }
            Page.Name.SETTINGS -> {
                wv.evaluateJs(script.getSettingGoToAdsPrefScript())
            }
            Page.Name.ADS_PREF -> {
                wv.evaluateJs(script.getAdsPrefGoToYourInfoPageScript())
            }
            Page.Name.DEMOGRAPHIC -> {
                wv.evaluateJs(script.getDemoGraphGoToBehaviorsPageScript())
            }
            Page.Name.BEHAVIORS -> {
                handler.postDelayed({
                    wv.evaluateJavascript(script.getBehaviorFetchCategoriesScript()) { value ->
                        val categories = newGsonInstance().fromJson<List<String>>(value)
                        viewModel.saveFbAdsPrefCategories(categories)
                    }
                }, 1000)
            }
            else -> {
                Tracer.DEBUG.log(
                    TAG,
                    "automateCategoriesFetching, unexpected page is $pageName"
                )
                showHelpRequiredState()
            }
        }
    }

    private fun automateAccountRegister(
        wv: WebView,
        pageName: Page.Name,
        script: AutomationScriptData
    ) {
        when (pageName) {
            Page.Name.LOGIN -> {
                startCheckLoginFailedLooper(wv, script)
                wv.evaluateJs(
                    script.getLoginScript(fbCredential!!.id, fbCredential!!.password)
                        ?: return
                )
            }
            Page.Name.SAVE_DEVICE -> {
                wv.evaluateJs(script.getSaveDeviceOkScript())
            }
            Page.Name.NEW_FEED -> {
                // permanently save cookies for next session
                CookieManager.getInstance().flush()
                wv.evaluateJs(script.getNewFeedGoToSettingPageScript())
            }
            Page.Name.SETTINGS -> {
                wv.evaluateJs(script.getSettingGoToArchivePageScript())
            }
            Page.Name.ARCHIVE -> {
                when {
                    isArchiveRequested() -> {
                        wv.evaluateVerificationJs(
                            script.getArchiveCreatingFileScript()!!,
                            callback = { processing ->
                                if (processing) {
                                    if (context == null) return@evaluateVerificationJs
                                    goToStillWaiting(archiveRequestedAt)
                                } else {
                                    if (context != null) {
                                        cancelNotification(context!!, NOTIFICATION_ID)
                                    }
                                    automateArchiveDownload(wv, script)
                                }
                            })
                    }
                    hasCredential() -> automateArchiveRequest(wv, script)
                    else -> {
                        checkArchiveIsCreating(wv, script)
                    }
                }
            }
            Page.Name.RE_AUTH -> {
                wv.evaluateJs(script.getReAuthScript(fbCredential!!.password))
            }

            else -> {
                Tracer.DEBUG.log(
                    TAG,
                    "automateCategoriesFetching, unexpected page is $pageName"
                )
                showHelpRequiredState()
            }
        }
    }

    private fun startCheckLoginFailedLooper(wv: WebView, script: AutomationScriptData) {
        val checkLoginFailed =
            fun(wv: WebView, script: AutomationScriptData, callback: Action1<Boolean>) {
                wv.evaluateVerificationJs(script.getCheckLoginFailedScript()!!) { failed ->
                    callback.invoke(failed)
                }
            }

        checkLoginFailed(wv, script, object : Action1<Boolean> {
            override fun invoke(failed: Boolean) {
                if (failed) {
                    showLoginFailedPopup()
                } else if (!checkLoginFailedLooperStopped) {
                    checkLoginFailed(wv, script, this)
                }
            }
        })
    }

    private fun handleUnexpectedPageDetected(wv: WebView) {

        // reload webview if detect the same page as previous one or unexpected page
        // it helps to refresh the JS context to corresponding latest page, avoid using the old one
        val reload = fun(wv: WebView) {
            if (reloadCount >= MAX_RELOAD_COUNT) {
                // got stuck here and could not continue automating
                Tracer.ERROR.log(
                    TAG,
                    "showHelpRequiredState since reloadCount >= MAX_RELOAD_COUNT"
                )
                showHelpRequiredState()
            } else {
                Log.d(TAG, "Reload: ${wv.url}")
                lastUrl = "" // reset to pass through after reloading
                wv.loadUrl(wv.url)
                reloadCount++
            }
        }

        handler.postDelayed({ reload(wv) }, 500)
    }

    private fun showLoginFailedPopup() {
        // TODO change text later
        dialogController.alert(
            "Error",
            "Incorrect authentication credentials.",
            tag = "login_failed"
        ) { finish() }
    }

    private fun showAutomatingState() {
        val bgColor = context?.getDrawable(R.color.cognac)
        layoutState.background = bgColor
        layoutRoot.background = bgColor
        tvMsg.text = ""
        viewCover.visible()
        tvAutomating.visible()
    }

    private fun showHelpRequiredState() {
        val bgColor = context?.getDrawable(R.color.international_klein_blue)
        layoutState.background = bgColor
        layoutRoot.background = bgColor
        tvMsg.setText(R.string.your_help_is_required)
        tvMsg.visible()
        viewCover.gone()
        tvAutomating.gone()
    }

    private fun automateArchiveRequest(
        wv: WebView,
        script: AutomationScriptData
    ) {
        wv.evaluateJs(script.getArchiveSelectJsonOptionScript(), success = {
            wv.evaluateJs(script.getArchiveSelectHighResolution(), success = {
                wv.evaluateJs(script.getArchiveCreateFileScript(), success = {
                    checkArchiveIsCreating(wv, script)
                })
            })
        })
    }

    private fun checkArchiveIsCreating(wv: WebView, script: AutomationScriptData) {
        wv.evaluateVerificationJs(
            script.getArchiveCreatingFileScript() ?: "",
            callback = { requested ->
                if (requested) {
                    archiveRequestedAt = System.currentTimeMillis()
                    viewModel.saveArchiveRequestedAt(archiveRequestedAt)
                }
            })
    }

    private fun automateArchiveDownload(
        wv: WebView,
        script: AutomationScriptData
    ) {
        wv.evaluateJs(script.getArchiveSelectDownloadTabScript(), success = {
            wv.evaluateJs(script.getArchiveDownloadFirstFileScript())
        })
    }

    private fun hasCredential() = fbCredential?.isValid() == true

    private fun isArchiveRequested() = archiveRequestedAt != -1L

    private fun registerAccount(
        credentialId: String,
        downloadArchiveCredential: DownloadArchiveCredential,
        accountData: AccountData
    ) {
        val registered = accountData.isValid()
        if (registered) {
            loadAccount(accountData) { account ->
                registerAccount(
                    account,
                    accountData.keyAlias,
                    credentialId,
                    downloadArchiveCredential,
                    true
                )
            }
        } else {
            val account = Account()
            saveAccount(account) { alias ->
                registerAccount(account, alias, credentialId, downloadArchiveCredential, false)
            }
        }
    }

    private fun registerAccount(
        account: Account,
        keyAlias: String,
        credentialId: String,
        downloadArchiveCredential: DownloadArchiveCredential,
        registered: Boolean
    ) {
        viewModel.registerAccount(
            account,
            downloadArchiveCredential.url,
            downloadArchiveCredential.cookie,
            keyAlias,
            credentialId,
            registered
        )
    }

    private fun loadAccount(accountData: AccountData, action: (Account) -> Unit) {
        val spec =
            KeyAuthenticationSpec.Builder(context!!).setKeyAlias(accountData.keyAlias)
                .setAuthenticationDescription(getString(R.string.your_authorization_is_required))
                .setAuthenticationRequired(accountData.authRequired).build()
        activity?.loadAccount(
            accountData.id,
            spec,
            dialogController,
            successAction = action,
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            invalidErrorAction = { e ->
                logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, e)
                dialogController.unexpectedAlert { navigator.exitApp() }
            })
    }

    private fun saveAccount(
        account: Account,
        successAction: (String) -> Unit
    ) {
        val keyAlias = account.generateKeyAlias()
        val spec = KeyAuthenticationSpec.Builder(context)
            .setKeyAlias(keyAlias)
            .setAuthenticationRequired(false).build()

        activity?.saveAccount(
            account,
            spec,
            dialogController,
            successAction = { successAction(keyAlias) },
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            invalidErrorAction = { e ->
                logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, e)
                dialogController.alert(
                    getString(R.string.error),
                    e?.message ?: getString(R.string.unexpected_error)
                ) { navigator.exitApp() }
            })
    }

    override fun observe() {
        super.observe()

        viewModel.registerAccountLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    OneSignal.setSubscription(true)
                    registered = true
                    progressBar.gone()
                    blocked = false
                    // reload to automate category fetching
                    wv.loadUrl(FB_ENDPOINT)

                    // expected page now is either LOGIN (if session is expired) or NEWFEED otherwise
                    expectedPage = listOf(Page.Name.LOGIN, Page.Name.NEW_FEED)
                }

                res.isError() -> {
                    wv.setDownloadListener(null)
                    progressBar.gone()
                    logger.logError(
                        Event.ARCHIVE_REQUEST_REGISTER_ACCOUNT_ERROR,
                        res.throwable() ?: UnknownException("unknown")
                    )

                    if (!connectivityHandler.isConnected()) {
                        dialogController.showNoInternetConnection {
                            finish()
                        }
                    } else if (!res.throwable()!!.isServiceUnsupportedError()) {
                        dialogController.alert(
                            R.string.error,
                            R.string.could_not_register_account
                        ) { finish() }
                    }
                    blocked = false
                }

                res.isLoading() -> {
                    progressBar.visible()
                    blocked = true
                }
            }
        })

        viewModel.saveFbAdsPrefCategoriesLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    viewModel.checkDataReady()
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "save fb ads pref categories error")
                    viewModel.checkDataReady()
                }
            }
        })

        viewModel.checkDataReadyLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val ready = res.data()!!
                    if (ready) {
                        viewModel.getExistingAccountData()
                    } else {
                        goToAnalyzing()
                    }
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "save fb ads pref categories error")
                }
            }
        })

        viewModel.prepareDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    val data = res.data()!!
                    val script = data.first
                    val hasCredential = data.second
                    if (hasCredential) {
                        CredentialData.load(
                            activity!!,
                            executor,
                            { credential ->
                                fbCredential = credential
                                loadPage(wv, FB_ENDPOINT, script)
                            },
                            { throwable ->
                                logger.logError(
                                    Event.ACCOUNT_LOAD_FB_CREDENTIAL_ERROR,
                                    throwable ?: UnknownException()
                                )
                                dialogController.unexpectedAlert {
                                    finish()
                                }
                            })
                    } else {
                        loadPage(wv, FB_ENDPOINT, script)
                    }
                }

                res.isError() -> {
                    progressBar.gone()
                    val error = res.throwable()
                    logger.logError(Event.ARCHIVE_REQUEST_PREPARE_DATA_ERROR, error)

                    if (!connectivityHandler.isConnected()) {
                        dialogController.showNoInternetConnection {
                            finish()
                        }
                    } else if (!res.throwable()!!.isServiceUnsupportedError()) {
                        if (error is UnknownException) {
                            dialogController.unexpectedAlert {
                                finish()
                            }
                        } else {
                            dialogController.alert(error) {
                                finish()
                            }
                        }
                    }
                }

                res.isLoading() -> {
                    progressBar.visible()
                }
            }
        })

        viewModel.saveArchiveRequestedAtLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    viewModel.checkNotificationEnabled()
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "save archive requested at error")
                    dialogController.unexpectedAlert { finish() }
                }
            }
        })

        viewModel.checkNotificationEnabledLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val enabled = res.data() ?: false
                    if (enabled) {
                        scheduleNotification()
                    }

                    goToArchiveRequested()
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "check notification enabled error")
                    dialogController.unexpectedAlert { finish() }
                }
            }
        })

        viewModel.getExistingAccountDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val accountData = res.data()!!
                    if (registered) {
                        navigator.anim(RIGHT_LEFT).startActivityAsRoot(MainActivity::class.java)
                    } else {
                        registerAccount(fbCredential!!.id, downloadArchiveCredential, accountData)
                    }
                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "get existing account error")
                    dialogController.unexpectedAlert { finish() }
                }
            }
        })
    }

    private fun finish() = navigator.anim(RIGHT_LEFT).popFragment()

    private fun goToAnalyzing() {
        val bundle =
            DataProcessingActivity.getBundle(
                getString(R.string.processing_data),
                getString(R.string.your_fb_data_archive_has_been_successfully)
            )
        navigator.anim(RIGHT_LEFT)
            .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
    }

    private fun goToStillWaiting(archiveRequestedAt: Long) {
        val msg =
            "${getString(R.string.sorry_fb_is_still_prepare)}\n\n${getString(
                R.string.you_requested_your_fb_archive_format
            ).format(
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
        val bundle =
            DataProcessingActivity.getBundle(
                getString(R.string.still_waiting),
                msg
            )
        navigator.anim(RIGHT_LEFT)
            .startActivityAsRoot(
                DataProcessingActivity::class.java,
                bundle
            )
    }

    private fun goToArchiveRequested() {
        val msg =
            "${getString(R.string.we_are_waiting_for_fb_2)}\n\n${getString(R.string.you_requested_your_fb_archive_format)
                .format(
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
        val bundle =
            DataProcessingActivity.getBundle(getString(R.string.data_requested), msg)
        navigator.anim(RIGHT_LEFT)
            .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
    }

    private fun scheduleNotification() {
        if (context == null) return
        val bundle = buildSimpleNotificationBundle(
            context!!,
            R.string.spring,
            R.string.just_remind_you,
            NOTIFICATION_ID,
            ArchiveRequestContainerActivity::class.java
        )
        pushDailyRepeatingNotification(
            context!!,
            bundle,
            System.currentTimeMillis() + 3 * AlarmManager.INTERVAL_DAY
        )
    }

    override fun onBackPressed(): Boolean {
        return finish()
    }
}