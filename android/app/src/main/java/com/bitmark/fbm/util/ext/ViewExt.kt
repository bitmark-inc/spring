/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.os.Handler
import android.view.View
import android.webkit.ValueCallback
import android.webkit.WebView
import android.widget.TextView
import androidx.annotation.ColorRes
import androidx.annotation.StringRes
import androidx.core.content.ContextCompat
import com.bitmark.fbm.logging.Tracer

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
    timeout: Long = 30000,
    callback: (Boolean) -> Unit
) {
    val startTime = System.currentTimeMillis()
    evaluateJavascript(script, object : ValueCallback<String> {
        override fun onReceiveValue(value: String?) {
            when {
                value?.toBoolean() == true                       -> callback(true)
                System.currentTimeMillis() - startTime < timeout -> evaluateJavascript(script, this)
                else                                             -> callback(false)
            }
        }
    })
}