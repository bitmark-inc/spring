/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.graphics.drawable.Drawable
import android.os.Handler
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.ColorRes
import androidx.annotation.StringRes
import androidx.core.content.ContextCompat
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.Page
import com.bitmark.fbm.data.model.fromString
import com.bitmark.fbm.data.model.value
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.callback.Action0
import com.bitmark.fbm.util.view.GlideUrlNoToken
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.target.Target
import com.google.android.material.snackbar.Snackbar
import kotlinx.android.synthetic.main.layout_snack_bar.view.*
import java.util.concurrent.atomic.AtomicInteger

fun View.gone(withAnim: Boolean = false) {
    if (withAnim) {
        animate().alpha(0.0f).setDuration(250)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator?) {
                    visibility = View.GONE
                }
            })
    } else {
        visibility = View.GONE
    }

}

fun View.visible(withAnim: Boolean = false) {
    if (withAnim) {
        animate().alpha(1.0f).setDuration(250)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator?) {
                    visibility = View.VISIBLE
                }
            })
    } else {
        visibility = View.VISIBLE
    }
}

fun View.invisible(withAnim: Boolean = false) {
    if (withAnim) {
        animate().alpha(0.0f).setDuration(250)
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator?) {
                    visibility = View.INVISIBLE
                }
            })
    } else {
        visibility = View.INVISIBLE
    }
}

fun View.setSafetyOnclickListener(action: (View?) -> Unit) {
    this.setOnClickListener(object : View.OnClickListener {

        var blocked = false

        val handler = Handler()

        override fun onClick(v: View?) {
            if (blocked) return

            blocked = true
            handler.postDelayed({
                blocked = false
            }, 500)
            action.invoke(v)
        }

    })
}

fun View.enable() {
    this.isEnabled = true
}

fun View.disable() {
    this.isEnabled = false
}

fun TextView.setText(@StringRes id: Int) {
    this.text = context.getString(id)
}

fun TextView.setTextColorRes(@ColorRes id: Int) {
    this.setTextColor(ContextCompat.getColor(context, id))
}

fun WebView.evaluateJs(script: String?, success: () -> Unit = {}, error: () -> Unit = {}) {
    evaluateJavascript(script) { result ->
        if (result.contains("ErrorUtils caught an error", true)) {
            Tracer.ERROR.log("WebView.evaluateJs()", "Script: $script, result:$result")
            error()
        } else {
            success()
        }
    }
}

fun WebView.evaluateVerificationJs(
    script: String,
    callback: (Boolean) -> Unit
) {
    evaluateJavascript(script) { value ->
        when {
            value.isBoolean() -> callback(value?.toBoolean() ?: false)
            else -> {
                Tracer.ERROR.log(
                    "WebView.evaluateVerificationJs()",
                    "Script: $script, value: $value"
                )
                callback(false)
            }
        }
    }
}

fun ViewGroup.createSnackbar(
    @StringRes title: Int, @StringRes
    message: Int, dismissCallback: () -> Unit = {}
): Snackbar {
    val snackbar = Snackbar.make(this, "", Snackbar.LENGTH_LONG)
    val layout = snackbar.view as Snackbar.SnackbarLayout
    val tvSnackbarDefault =
        layout.findViewById<TextView>(com.google.android.material.R.id.snackbar_text)
    tvSnackbarDefault.invisible()

    val snackbarView = LayoutInflater.from(context).inflate(R.layout.layout_snack_bar, null)
    with(snackbarView) {
        tvTitle.text = context.getString(title)
        tvMsg.text = context.getString(message)
    }
    layout.setPadding(0, 0, 0, 0)
    layout.addView(snackbarView)
    snackbar.addCallback(object : Snackbar.Callback() {
        override fun onDismissed(transientBottomBar: Snackbar?, event: Int) {
            super.onDismissed(transientBottomBar, event)
            dismissCallback()
        }
    })
    return snackbar
}

fun ImageView.load(
    url: String,
    cache: String? = null,
    success: () -> Unit = {},
    error: (GlideException?) -> Unit = {},
    placeholder: Int = R.drawable.bg_athens_gray
) =
    Glide.with(context).load(
        GlideUrlNoToken(
            url,
            cache
        )
    ).placeholder(placeholder).listener(object :
        RequestListener<Drawable> {
        override fun onLoadFailed(
            e: GlideException?,
            model: Any?,
            target: Target<Drawable>?,
            isFirstResource: Boolean
        ): Boolean {
            error(e)
            return false
        }

        override fun onResourceReady(
            resource: Drawable?,
            model: Any?,
            target: Target<Drawable>?,
            dataSource: DataSource?,
            isFirstResource: Boolean
        ): Boolean {
            success()
            return false
        }

    }).into(this)

fun WebView.detectPage(
    pages: List<Page>,
    tag: String = "WebView.detectPage()",
    timeout: Long = 15000,
    callback: (Page.Name) -> Unit
) {
    var detectedPage = ""
    val evaluated = AtomicInteger(0)

    val evaluateJs = fun(p: Page, onDone: () -> Unit) {
        this.evaluateVerificationJs(p.detection) { detected ->
            evaluated.incrementAndGet()
            if (detected) {
                detectedPage = p.name.value
            } else {
                // error go here
                Tracer.DEBUG.log(tag, "evaluateJavascript: ${p.detection}, result: $detected")
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
                handler.postDelayed({ execute(this) }, 500)
            } else {
                if (detectedPage == "") {
                    // could not detect the page
                    // log event with all breadcrumbs
                    callback(Page.Name.UNKNOWN)
                }
                Tracer.DEBUG.log(tag, "detected the current page: $detectedPage")
                callback(Page.Name.fromString(detectedPage))
            }
        }
    })
}