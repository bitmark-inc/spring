/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.os.Bundle
import android.os.Handler
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.NONE
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.share
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.layout_webview.*


class WebViewActivity : AppCompatActivity() {

    companion object {

        private const val URL = "url"

        private const val TITLE = "title"

        fun getBundle(
            url: String,
            title: String
        ): Bundle {
            val bundle = Bundle()
            bundle.putString(URL, url)
            bundle.putString(TITLE, title)
            return bundle
        }
    }

    private val navigator = Navigator(this)

    private val handler = Handler()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.layout_webview)
    }

    override fun onPostCreate(savedInstanceState: Bundle?) {
        super.onPostCreate(savedInstanceState)
        initComponents()
    }

    override fun onDestroy() {
        deinitComponents()
        super.onDestroy()
    }

    private fun initComponents() {
        val url = intent?.extras?.getString(URL) ?: error("Missing URL")
        val title = intent?.extras?.getString(TITLE) ?: error("Missing title")

        tvTitle.text = title

        wv.settings.javaScriptEnabled = true

        wv.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                super.onProgressChanged(view, newProgress)
                progressBar.progress = newProgress
                if (newProgress >= 100) {
                    progressBar.gone()
                } else {
                    progressBar.visible()
                }
            }
        }

        wv.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                view?.loadUrl(url)
                return super.shouldOverrideUrlLoading(view, url)
            }
        }

        ivBack.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

        ivShare.setSafetyOnclickListener {
            navigator.anim(NONE).share(wv.url)
        }

        // a bit delay for better performance
        handler.postDelayed({ wv.loadUrl(url) }, 200)
    }

    private fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        wv.webChromeClient = null
        wv.webViewClient = null
    }

    override fun onBackPressed() {
        navigator.anim(RIGHT_LEFT).finishActivity()
        super.onBackPressed()
    }
}