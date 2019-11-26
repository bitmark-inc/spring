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
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.lifecycle.Observer
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.cryptography.crypto.encoder.Hex
import com.bitmark.cryptography.crypto.encoder.Raw
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.AutomationScriptData
import com.bitmark.fbm.data.model.Page
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.notification.buildSimpleNotificationBundle
import com.bitmark.fbm.feature.notification.cancelNotification
import com.bitmark.fbm.feature.notification.pushDailyRepeatingNotification
import com.bitmark.fbm.feature.register.archiverequest.ArchiveRequestContainerActivity
import com.bitmark.fbm.feature.register.notification.RegisterNotificationActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.callback.Action0
import com.bitmark.fbm.util.ext.evaluateJs
import com.bitmark.fbm.util.ext.evaluateVerificationJs
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import kotlinx.android.synthetic.main.fragment_archive_request.*
import java.net.URL
import java.util.concurrent.atomic.AtomicInteger
import javax.inject.Inject


class ArchiveRequestFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "ArchiveRequestFragment"

        private const val ARCHIVE_DOWNLOAD_HOST = "bigzipfiles.facebook.com"

        private const val FB_ENDPOINT = "https://m.facebook.com"

        private const val FB_ID = "fb_id"

        private const val FB_PASSWORD = "fb_password"

        private const val ARCHIVE_REQUESTED = "archive_requested"

        private const val NOTIFICATION_ID = 0xA1

        fun newInstance(
            fbId: String? = null,
            fbPassword: String? = null,
            archiveRequested: Boolean = false
        ): ArchiveRequestFragment {
            val fragment = ArchiveRequestFragment()
            val bundle = Bundle()
            if (fbId != null) bundle.putString(FB_ID, fbId)
            if (fbPassword != null) bundle.putString(FB_PASSWORD, fbPassword)
            bundle.putBoolean(ARCHIVE_REQUESTED, archiveRequested)
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

    private var fbId: String? = null

    private var fbPassword: String? = null

    private var archiveRequested = false

    private var handlingPageUrl = ""

    override fun layoutRes(): Int = R.layout.fragment_archive_request

    override fun viewModel(): BaseViewModel? = null

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        archiveRequested = arguments?.getBoolean(ARCHIVE_REQUESTED) ?: false
        fbId = arguments?.getString(FB_ID)
        fbPassword = arguments?.getString(FB_PASSWORD)

        viewModel.getAutomationScript()
    }

    override fun deinitComponents() {
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
                    handlePageLoaded(view!!, script, view.url)
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
                    registerAccount(urlString, cookie)
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

    private fun handlePageLoaded(wv: WebView, script: AutomationScriptData, urlString: String) {
        // workaround to avoid calling multi times in same page url
        if (handlingPageUrl == urlString) return
        handlingPageUrl = urlString
        detectPage(wv, script) { name ->
            when (name) {
                Page.Name.LOGIN.value -> {
                    if (hasCredential()) {
                        wv.evaluateJs(
                            script.getLoginScript(fbId!!, fbPassword!!) ?: return@detectPage
                        )
                    }
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
                    if (hasCredential() || archiveRequested) {
                        wv.evaluateJs(script.getNewFeedGoToSettingPageScript())
                    } else {
                        // TODO show instruction
                    }
                }
                Page.Name.SETTINGS.value -> {
                    if (hasCredential() || archiveRequested) {
                        wv.evaluateJs(script.getSettingGoToArchivePageScript())
                    } else {
                        // TODO show instruction
                    }
                }
                Page.Name.ARCHIVE.value -> {
                    when {
                        archiveRequested -> {
                            wv.evaluateVerificationJs(
                                script.getArchiveCreatingFileScript()!!,
                                callback = { processing ->
                                    if (processing) {
                                        dialogController.alert(
                                            "Your archive request is processing!",
                                            "Your archive is processing and will be available soon"
                                        )
                                    } else {
                                        if (context != null) cancelNotification(
                                            context!!,
                                            NOTIFICATION_ID
                                        )
                                        automateArchiveDownload(wv, script)
                                    }
                                })
                        }
                        hasCredential()  -> automateArchiveRequest(wv, script)
                        else             -> {
                            // TODO show instruction
                        }
                    }
                }
                Page.Name.RE_AUTH.value -> {
                    if (hasCredential()) {
                        wv.evaluateJs(script.getReAuthScript(fbPassword!!))
                    } else {
                        // TODO show instruction
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
        val timeout = 3000

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
                        logger.logError(
                            Event.FB_ARCHIVE_AUTOMATE_PAGE_DETECTION_FAILED,
                            Throwable("could not detect the current page")
                        )
                    }
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
            wv.evaluateJs(script.getArchiveCreateFileScript(), success = {
                wv.evaluateVerificationJs(
                    script.getArchiveCreatingFileScript() ?: "",
                    callback = { requested ->
                        if (requested) {
                            archiveRequested = true
                            viewModel.saveArchiveRequestedFlag()
                        }
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

    private fun hasCredential() =
        !fbId.isNullOrBlank() && !fbPassword.isNullOrBlank()

    private fun registerAccount(archiveUrl: String, cookie: String) {
        val account = Account()
        saveAccount(account) { alias ->
            val requester = account.accountNumber
            val timestamp = System.currentTimeMillis().toString()
            val signature = Hex.HEX.encode(account.sign(Raw.RAW.decode(timestamp)))
            viewModel.registerAccount(
                requester,
                timestamp,
                signature,
                archiveUrl,
                cookie,
                alias
            )
        }
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
                    Tracer.ERROR.log(
                        TAG,
                        "save account failed: ${throwable?.message ?: "unknown"}"
                    )
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
                    navigator.anim(RIGHT_LEFT)
                        .startActivityAsRoot(RegisterNotificationActivity::class.java)
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

        viewModel.getAutomationScriptLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    val script = res.data()!!
                    loadPage(wv, FB_ENDPOINT, script)
                }

                res.isError()   -> {
                    progressBar.gone()
                    // TODO handle error later
                }

                res.isLoading() -> {
                    progressBar.visible()
                }
            }
        })

        viewModel.saveArchiveRequestedFlagLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    scheduleNotification()
                }
            }
        })
    }

    private fun scheduleNotification() {
        if (context == null) return
        val bundle = buildSimpleNotificationBundle(
            context!!,
            R.string.your_archive_is_ready,
            R.string.please_check_if_your_archive_is_ready,
            NOTIFICATION_ID,
            ArchiveRequestContainerActivity::class.java
        )
        pushDailyRepeatingNotification(
            context!!,
            bundle,
            System.currentTimeMillis() + AlarmManager.INTERVAL_DAY
        )
    }

    override fun onBackPressed(): Boolean {
        return navigator.anim(RIGHT_LEFT).popFragment()
    }
}