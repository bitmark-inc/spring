/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature

import android.app.Activity
import androidx.annotation.StringRes
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatDialog
import java.util.*

class DialogController(private val activity: Activity) {

    private val queue = ArrayDeque<AppCompatDialog>()

    var showingDialog: AppCompatDialog? = null
        private set

    fun isShowing() = showingDialog != null

    fun show(dialog: AppCompatDialog) {
        if (isShowing() && dialog != showingDialog)
            queue.add(dialog)
        else dialog.show()
    }

    fun dismiss(dialog: AppCompatDialog, dismissListener: () -> Unit = {}) {
        dialog.setOnDismissListener {
            dismissListener.invoke()
            showNext()
        }
        dialog.dismiss()
    }

    fun alert(
        title: String,
        message: String,
        text: String = activity.getString(android.R.string.ok),
        cancelable: Boolean = false,
        clickEvent: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(text) { d, _ ->
                    d.dismiss()
                    clickEvent.invoke()
                    showNext()
                }
                .setCancelable(cancelable).create()
        if (isShowing())
            queue.add(dialog)
        else dialog.show()
    }

    fun alert(
        @StringRes title: Int, @StringRes message: Int, @StringRes text: Int = android.R.string.ok,
        cancelable: Boolean = false,
        clickEvent: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(text) { d, _ ->
                    d.dismiss()
                    clickEvent.invoke()
                    showNext()
                }
                .setCancelable(cancelable).create()
        if (isShowing())
            queue.add(dialog)
        else dialog.show()
    }

    fun confirm(
        title: String,
        message: String,
        cancelable: Boolean = false,
        positive: String = activity.getString(android.R.string.ok),
        positiveEvent: () -> Unit = {},
        negative: String = activity.getString(android.R.string.cancel),
        negativeEvent: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(positive) { d, _ ->
                    d.dismiss()
                    positiveEvent.invoke()
                    showNext()
                }.setNegativeButton(negative) { d, _ ->
                    d.dismiss()
                    negativeEvent.invoke()
                    if (isQueueing()) {
                        val dialog = queue.first
                        dialog.show()
                    }
                }
                .setCancelable(cancelable).create()
        if (isShowing())
            queue.add(dialog)
        else dialog.show()
    }

    fun confirm(
        @StringRes title: Int,
        @StringRes message: Int,
        cancelable: Boolean = false,
        @StringRes positive: Int = android.R.string.ok,
        positiveEvent: () -> Unit = {},
        @StringRes negative: Int = android.R.string.cancel,
        negativeEvent: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(positive) { d, _ ->
                    d.dismiss()
                    positiveEvent.invoke()
                    showNext()
                }.setNegativeButton(negative) { d, _ ->
                    d.dismiss()
                    negativeEvent.invoke()
                    showNext()
                }
                .setCancelable(cancelable).create()
        if (isShowing())
            queue.add(dialog)
        else dialog.show()
    }

    fun dismissShowing() {
        if (isShowing()) showingDialog?.dismiss()
    }

    fun dismiss() {
        dismissShowing()
        while (queue.isNotEmpty()) {
            queue.poll().dismiss()
        }
    }

    private fun isQueueing() = !queue.isEmpty()

    private fun showNext() {
        if (isQueueing()) {
            val dialog = queue.first
            dialog.show()
        }
    }
}