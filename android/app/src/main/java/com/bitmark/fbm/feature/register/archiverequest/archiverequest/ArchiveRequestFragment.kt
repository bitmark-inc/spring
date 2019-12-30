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
import com.bitmark.apiservice.utils.callback.Callback1
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.*
import com.bitmark.fbm.data.source.remote.api.error.UnknownException
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.notification.buildSimpleNotificationBundle
import com.bitmark.fbm.feature.notification.cancelNotification
import com.bitmark.fbm.feature.notification.pushDailyRepeatingNotification
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.dataprocessing.DataProcessingActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.callback.Action0
import com.bitmark.fbm.util.callback.Action1
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.fragment_archive_request.*
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import javax.inject.Inject

class ArchiveRequestFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "ArchiveRequestFragment"

        private const val ARCHIVE_DOWNLOAD_HOST = "bigzipfiles.facebook.com"

        private const val FB_ENDPOINT = "https://m.facebook.com"

        private const val ARCHIVE_REQUESTED_AT = "archive_requested_at"

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
            Page.Name.SETTINGS to listOf(Page.Name.ARCHIVE)
        )

        fun newInstance(
            requestedAt: Long = -1L
        ): ArchiveRequestFragment {
            val fragment = ArchiveRequestFragment()
            val bundle = Bundle()
            bundle.putLong(ARCHIVE_REQUESTED_AT, requestedAt)
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
                    handlePageLoaded(view!!, script)
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

        if (needAutomate()) {
            showAutomatingState()
        }
    }

    private fun handlePageLoaded(wv: WebView, script: AutomationScriptData) {
        // workaround to avoid callback called multi times with the same url
        if (lastUrl == wv.url) return

        lastUrl = wv.url
        detectPage(wv, script) { name ->
            val unexpectedPageDetected = expectedPage != null && !expectedPage!!.contains(name)
            if (unexpectedPageDetected) {
                handleUnexpectedPageDetected(wv)
            } else {
                if (needAutomate()) {
                    showAutomatingState()
                }
                reloadCount = 0 // reset after detect expected page
                expectedPage = EXPECTED_PAGES[name]
                when (name) {
                    Page.Name.LOGIN -> {
                        startCheckLoginFailedLooper(wv, script)
                        if (needAutomate()) {
                            wv.evaluateJs(
                                script.getLoginScript(fbCredential!!.id, fbCredential!!.password)
                                    ?: return@detectPage
                            )
                        }
                    }
                    Page.Name.ACCOUNT_PICKING -> {
                        // do nothing now
                    }
                    Page.Name.SAVE_DEVICE -> {
                        if (needAutomate()) {
                            wv.evaluateJs(script.getSaveDeviceOkScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.NEW_FEED -> {
                        // permanently save cookies for next session
                        CookieManager.getInstance().flush()
                        if (needAutomate()) {
                            wv.evaluateJs(script.getNewFeedGoToSettingPageScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.SETTINGS -> {
                        if (needAutomate()) {
                            wv.evaluateJs(script.getSettingGoToArchivePageScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.ARCHIVE -> {
                        when {
                            isArchiveRequested() -> {
                                wv.evaluateVerificationJs(
                                    script.getArchiveCreatingFileScript()!!,
                                    callback = { processing ->
                                        if (processing) {
                                            if (context == null) return@evaluateVerificationJs
                                            val bundle =
                                                DataProcessingActivity.getBundle(
                                                    getString(R.string.still_waiting),
                                                    getString(R.string.you_requested_your_fb_data_format_2).format(
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
                                                    )
                                                )
                                            navigator.anim(RIGHT_LEFT)
                                                .startActivityAsRoot(
                                                    DataProcessingActivity::class.java,
                                                    bundle
                                                )

                                        } else {
                                            if (context != null) {
                                                cancelNotification(context!!, NOTIFICATION_ID)
                                            }
                                            automateArchiveDownload(wv, script)
                                        }
                                    })
                            }
                            hasCredential()      -> automateArchiveRequest(wv, script)
                            else                 -> {
                                checkArchiveIsCreating(wv, script)
                            }
                        }
                    }
                    Page.Name.RE_AUTH -> {
                        if (needAutomate()) {
                            wv.evaluateJs(script.getReAuthScript(fbCredential!!.password))
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.UNKNOWN -> {
                        // could not detect the current page
                        if (needAutomate()) {
                            showHelpRequiredState()
                        }
                    }
                }
            }

            // stop checking login failed looper after leaving LOGIN page
            if (name != Page.Name.LOGIN) {
                checkLoginFailedLooperStopped = true
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
        // only automate if has fb credential or archive is already requested
        if (!needAutomate()) return

        // reload webview if detect the same page as previous one or unexpected page
        // it helps to refresh the JS context to corresponding latest page, avoid using the old one
        val reload = fun(wv: WebView) {
            if (reloadCount >= MAX_RELOAD_COUNT) {
                // got stuck here and could not continue automating
                if (needAutomate()) {
                    showHelpRequiredState()
                }
            } else {
                Log.d(TAG, "Reload: ${wv.url}")
                lastUrl = "" // reset to pass through after reloading
                wv.loadUrl(wv.url)
                reloadCount++
            }
        }

        reload(wv)
    }

    private fun showLoginFailedPopup() {
        // TODO change text later
        dialogController.alert(
            "Error",
            "Incorrect authentication credentials.",
            tag = "login failed"
        ) { navigator.anim(RIGHT_LEFT).popFragment() }
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
        viewCover.gone()
        tvAutomating.gone()
    }

    private fun detectPage(
        wv: WebView,
        script: AutomationScriptData,
        callback: (Page.Name) -> Unit
    ) {
        var detectedPage = ""
        val evaluated = AtomicInteger(0)
        val pages = script.pages
        val timeout = 30000 // 30 sec

        val evaluateJs = fun(p: Page, onDone: () -> Unit) {
            wv.evaluateVerificationJs(p.detection) { detected ->
                evaluated.incrementAndGet()
                if (detected) {
                    detectedPage = p.name.value
                } else {
                    // error go here
                    Tracer.DEBUG.log(TAG, "evaluateJavascript: ${p.detection}, result: $detected")
                }
                onDone()
            }
        }

        val execute = fun(onDone: Action0) {
            evaluated.set(0)
            for (page in pages) {
                evaluateJs(page) {
                    if (evaluated.get() == pages.size) {
                        onDone.invoke()
                    }
                }
            }
        }

        val startTime = System.currentTimeMillis()
        execute(object : Action0 {
            override fun invoke() {
                if (detectedPage == "" && System.currentTimeMillis() - startTime < timeout) {
                    execute(this)
                } else {
                    if (detectedPage == "") {
                        // could not detect the page
                        // log event with all breadcrumbs
                        Tracer.ERROR.log(TAG, "could not detect the current page")
                        logger.logError(
                            Event.ARCHIVE_REQUEST_AUTOMATE_PAGE_DETECTION_ERROR,
                            "could not detect the current page"
                        )
                        callback(Page.Name.UNKNOWN)
                    }
                    Tracer.DEBUG.log(TAG, "detected the current page: $detectedPage")
                    callback(Page.Name.fromString(detectedPage))
                }
            }
        })
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

    private fun needAutomate() = hasCredential() || isArchiveRequested()

    private fun registerAccount(
        downloadArchiveCredential: DownloadArchiveCredential,
        accountData: AccountData
    ) {
        val registered = accountData.isValid()
        if (registered) {
            loadAccount(accountData) { account ->
                registerAccount(account, accountData.keyAlias, downloadArchiveCredential, true)
            }
        } else {
            val account = Account()
            saveAccount(account) { alias ->
                registerAccount(account, alias, downloadArchiveCredential, false)
            }
        }
    }

    private fun registerAccount(
        account: Account,
        keyAlias: String,
        credential: DownloadArchiveCredential,
        registered: Boolean
    ) {
        viewModel.registerAccount(
            account,
            credential.url,
            credential.cookie,
            keyAlias,
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
                    registered = true
                    progressBar.gone()
                    val bundle =
                        DataProcessingActivity.getBundle(
                            getString(R.string.analyzing_data),
                            getString(R.string.your_fb_data_archive_has_been_successfully)
                        )
                    navigator.anim(RIGHT_LEFT)
                        .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
                    blocked = false
                }

                res.isError()   -> {
                    progressBar.gone()
                    logger.logError(
                        Event.ARCHIVE_REQUEST_REGISTER_ACCOUNT_ERROR,
                        res.throwable() ?: UnknownException("unknown")
                    )
                    dialogController.alert(
                        R.string.error,
                        R.string.could_not_register_account
                    ) { navigator.finishActivity() }
                    blocked = false
                }

                res.isLoading() -> {
                    progressBar.visible()
                    blocked = true
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
                            object : Callback1<CredentialData> {
                                override fun onSuccess(credential: CredentialData?) {
                                    fbCredential = credential!!
                                    loadPage(wv, FB_ENDPOINT, script)
                                }

                                override fun onError(throwable: Throwable?) {
                                    logger.logError(
                                        Event.ACCOUNT_LOAD_FB_CREDENTIAL_ERROR,
                                        throwable ?: UnknownException()
                                    )
                                    dialogController.unexpectedAlert {
                                        navigator.anim(RIGHT_LEFT).finishActivity()
                                    }
                                }

                            })
                    } else {
                        loadPage(wv, FB_ENDPOINT, script)
                    }
                }

                res.isError()   -> {
                    progressBar.gone()
                    val error = res.throwable()
                    logger.logError(Event.ARCHIVE_REQUEST_PREPARE_DATA_ERROR, error)
                    if (error is UnknownException) {
                        dialogController.unexpectedAlert {
                            navigator.anim(RIGHT_LEFT).finishActivity()
                        }
                    } else {
                        dialogController.alert(error) { navigator.finishActivity() }
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

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "save archive requested at error")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
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
                            )
                        )
                    navigator.anim(RIGHT_LEFT)
                        .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "check notification enabled error")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })

        viewModel.getExistingAccountDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val account = res.data()!!
                    if(registered) return@Observer
                    registerAccount(downloadArchiveCredential, account)
                }

                res.isError()   -> {
                    logger.logSharedPrefError(res.throwable(), "get existing account error")
                    dialogController.unexpectedAlert { navigator.anim(RIGHT_LEFT).finishActivity() }
                }
            }
        })
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
        return navigator.anim(RIGHT_LEFT).popFragment()
    }
}