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
import android.view.View
import android.webkit.*
import androidx.lifecycle.Observer
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.apiservice.utils.callback.Callback1
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.*
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

        private const val ARCHIVE_REQUESTED_TIMESTAMP = "archive_requested_timestamp"

        private const val NOTIFICATION_ID = 0xA1

        private val EXPECTED_PAGES = mapOf(
            Page.Name.LOGIN to listOf(Page.Name.SAVE_DEVICE, Page.Name.NEW_FEED),
            Page.Name.SAVE_DEVICE to listOf(Page.Name.NEW_FEED),
            Page.Name.NEW_FEED to listOf(Page.Name.SETTINGS),
            Page.Name.SETTINGS to listOf(Page.Name.ARCHIVE)
        )

        fun newInstance(
            archiveRequestedTimestamp: Long = -1L
        ): ArchiveRequestFragment {
            val fragment = ArchiveRequestFragment()
            val bundle = Bundle()
            bundle.putLong(ARCHIVE_REQUESTED_TIMESTAMP, archiveRequestedTimestamp)
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

    private lateinit var executor: ExecutorService

    private val handler = Handler()

    private lateinit var fbCredential: CredentialData

    private var archiveRequestedTimestamp = -1L

    private var expectedPage: List<Page.Name>? = null

    private var lastUrl = ""

    private lateinit var downloadArchiveCredential: DownloadArchiveCredential

    override fun layoutRes(): Int = R.layout.fragment_archive_request

    override fun viewModel(): BaseViewModel? = null

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        archiveRequestedTimestamp = arguments?.getLong(ARCHIVE_REQUESTED_TIMESTAMP) ?: -1L

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
                    progressBar.gone()
                    handlePageLoaded(view!!, script)
                } else {
                    progressBar.visible()
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
                if (host == ARCHIVE_DOWNLOAD_HOST) {
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
    }

    private fun handlePageLoaded(wv: WebView, script: AutomationScriptData) {
        // workaround to prevent multi method call between the same urls
        if (lastUrl == wv.url) return
        val reload = fun(wv: WebView) {
            lastUrl = "" // reset to pass through after reloading
            wv.loadUrl(wv.url)
        }
        lastUrl = wv.url
        detectPage(wv, script) { name ->
            val pageName = Page.Name.fromString(name)
            val unexpectedOccurred = expectedPage != null && !expectedPage!!.contains(pageName)
            if (unexpectedOccurred) {
                if (pageName == Page.Name.LOGIN) {
                    checkLoginFailed(wv, script) { failed ->
                        if (failed) {
                            // TODO change text later
                            dialogController.alert(
                                "Error",
                                "Incorrect authentication credentials."
                            ) {
                                navigator.anim(RIGHT_LEFT).popFragment()
                            }
                        } else {
                            reload(wv)
                        }
                    }
                } else {
                    reload(wv)
                }
            } else {
                expectedPage = EXPECTED_PAGES[pageName]
                when (name) {
                    Page.Name.LOGIN.value -> {
                        if (hasCredential()) {
                            wv.evaluateJs(
                                script.getLoginScript(fbCredential.id, fbCredential.password)
                                    ?: return@detectPage
                            )
                        }
                    }
                    Page.Name.ACCOUNT_PICKING.value -> {
                        // do nothing now
                    }
                    Page.Name.SAVE_DEVICE.value -> {
                        if (hasCredential()) {
                            wv.evaluateJs(script.getSaveDeviceOkScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.NEW_FEED.value -> {
                        // permanently save cookies for next session
                        CookieManager.getInstance().flush()
                        if (hasCredential() || isArchiveRequested()) {
                            wv.evaluateJs(script.getNewFeedGoToSettingPageScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.SETTINGS.value -> {
                        if (hasCredential() || isArchiveRequested()) {
                            wv.evaluateJs(script.getSettingGoToArchivePageScript())
                        } else {
                            // TODO show instruction
                        }
                    }
                    Page.Name.ARCHIVE.value -> {
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
                                                            archiveRequestedTimestamp,
                                                            DateTimeUtil.DATE_FORMAT_3
                                                        ),
                                                        DateTimeUtil.millisToString(
                                                            archiveRequestedTimestamp,
                                                            DateTimeUtil.TIME_FORMAT_1
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
                                // TODO show instruction
                            }
                        }
                    }
                    Page.Name.RE_AUTH.value -> {
                        if (hasCredential()) {
                            wv.evaluateJs(script.getReAuthScript(fbCredential.password))
                        } else {
                            // TODO show instruction
                        }
                    }
                }
            }
        }

    }

    private fun detectPage(
        wv: WebView,
        script: AutomationScriptData,
        callback: (String) -> Unit
    ) {
        var detectedPage = ""
        val evaluated = AtomicInteger(0)
        val pages = script.pages
        val timeout = 30000 // 30 sec

        val evaluateJs = fun(p: Page, onDone: () -> Unit) {
            wv.evaluateJavascript(p.detection) { result ->
                evaluated.incrementAndGet()
                if (result?.toBoolean() == true) {
                    detectedPage = p.name.value
                } else if (!result.equals("false", true)) {
                    // error go here
                    Tracer.ERROR.log(TAG, result)
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
                    }
                    Tracer.DEBUG.log(TAG, "detected the current page: $detectedPage")
                    callback(detectedPage)
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
                    wv.evaluateVerificationJs(
                        script.getArchiveCreatingFileScript() ?: "",
                        callback = { requested ->
                            if (requested) {
                                archiveRequestedTimestamp = System.currentTimeMillis()
                                viewModel.saveArchiveRequestedAt(archiveRequestedTimestamp)
                            }
                        })
                })
            })
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

    private fun checkLoginFailed(
        wv: WebView,
        script: AutomationScriptData,
        callback: (Boolean) -> Unit
    ) {
        wv.evaluateVerificationJs(script.getCheckLoginFailedScript()!!, callback = callback)
    }

    private fun hasCredential() = fbCredential.isValid()

    private fun isArchiveRequested() = archiveRequestedTimestamp != -1L

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
                dialogController.alert(
                    R.string.error,
                    R.string.unexpected_error
                ) { navigator.exitApp() }
            })
    }

    private fun saveAccount(
        account: Account,
        successAction: (String) -> Unit
    ) {
        val keyAlias =
            "%s.%d.encryption_key".format(
                account.accountNumber,
                System.currentTimeMillis()
            )
        val accountAuthBuilder = KeyAuthenticationSpec.Builder(context)
            .setKeyAlias(keyAlias)
            .setAuthenticationRequired(false)

        account.saveToKeyStore(
            activity,
            accountAuthBuilder.build(),
            object : Callback0 {
                override fun onSuccess() {
                    successAction(keyAlias)
                }

                override fun onError(throwable: Throwable?) {
                    logger.logError(Event.ACCOUNT_SAVE_TO_KEY_STORE_ERROR, throwable)
                    dialogController.alert(
                        getString(R.string.error),
                        throwable?.message ?: getString(R.string.unexpected_error)
                    )
                }

            })
    }

    override fun observe() {
        super.observe()

        viewModel.registerAccountLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
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
                    dialogController.alert(R.string.error, R.string.could_not_register_account)
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
                    val fbCredentialAlias = data.second
                    CredentialData.load(
                        activity!!,
                        fbCredentialAlias,
                        executor,
                        object : Callback1<CredentialData> {
                            override fun onSuccess(credential: CredentialData?) {
                                fbCredential = credential!!
                                loadPage(wv, FB_ENDPOINT, script)
                            }

                            override fun onError(throwable: Throwable?) {
                                Tracer.ERROR.log(TAG, throwable?.message ?: "unknown")
                                dialogController.alert(
                                    R.string.error,
                                    R.string.unexpected_error
                                )
                            }

                        })
                }

                res.isError()   -> {
                    progressBar.gone()
                    val error = res.throwable()
                    logger.logError(Event.ARCHIVE_REQUEST_PREPARE_DATA_ERROR, error)
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    )
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
                    logger.logError(
                        Event.SHARE_PREF_ERROR,
                        "$TAG: save archive requested at error: ${res.throwable() ?: "unknown"}"
                    )
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    ) { navigator.exitApp() }
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
                                    archiveRequestedTimestamp,
                                    DateTimeUtil.DATE_FORMAT_3
                                ),
                                DateTimeUtil.millisToString(
                                    archiveRequestedTimestamp,
                                    DateTimeUtil.TIME_FORMAT_1
                                )
                            )
                        )
                    navigator.anim(RIGHT_LEFT)
                        .startActivityAsRoot(DataProcessingActivity::class.java, bundle)
                }
            }
        })

        viewModel.getExistingAccountDataLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val account = res.data()!!
                    registerAccount(downloadArchiveCredential, account)
                }

                res.isError()   -> {
                    logger.logError(
                        Event.SHARE_PREF_ERROR,
                        "$TAG: get existing account error: ${res.throwable() ?: "unknown"}"
                    )
                    dialogController.alert(
                        R.string.error,
                        R.string.unexpected_error
                    ) { navigator.exitApp() }
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