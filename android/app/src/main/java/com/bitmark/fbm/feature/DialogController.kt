/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature

import android.app.Activity
import android.content.DialogInterface
import androidx.annotation.StringRes
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatDialog
import java.util.*

class DialogController(private val activity: Activity) {

    private val queue = ArrayDeque<AppCompatDialog>()

    var showingDialog: AppCompatDialog? = null
        private set

    private fun dismissListener(forwarder: () -> Unit = {}) =
        DialogInterface.OnDismissListener { dialog ->
            showingDialog = null
            forwarder()
        }

    fun isShowing() = showingDialog != null

    fun show(dialog: AppCompatDialog, dismissCallback: () -> Unit = {}) {
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing() && dialog != showingDialog) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
    }

    fun dismiss(dialog: AppCompatDialog, dismissCallback: () -> Unit = {}) {
        dialog.setOnDismissListener(dismissListener {
            dismissCallback()
            showNext()
        })
        dialog.dismiss()
    }

    fun alert(
        title: String,
        message: String,
        text: String = activity.getString(android.R.string.ok),
        cancelable: Boolean = false,
        clickEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(text) { d, _ ->
                    d.dismiss()
                    clickEvent.invoke()
                    showNext()
                }
                .setCancelable(cancelable).create()
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing()) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
    }

    fun alert(
        @StringRes title: Int, @StringRes message: Int, @StringRes text: Int = android.R.string.ok,
        cancelable: Boolean = false,
        clickEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        val dialog =
            AlertDialog.Builder(activity).setTitle(title).setMessage(message)
                .setPositiveButton(text) { d, _ ->
                    d.dismiss()
                    clickEvent.invoke()
                    showNext()
                }
                .setCancelable(cancelable).create()
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing()) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
    }

    fun confirm(
        title: String,
        message: String,
        cancelable: Boolean = false,
        positive: String = activity.getString(android.R.string.ok),
        positiveEvent: () -> Unit = {},
        negative: String = activity.getString(android.R.string.cancel),
        negativeEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
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
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing()) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
    }

    fun confirm(
        @StringRes title: Int,
        @StringRes message: Int,
        cancelable: Boolean = false,
        @StringRes positive: Int = android.R.string.ok,
        positiveEvent: () -> Unit = {},
        @StringRes negative: Int = android.R.string.cancel,
        negativeEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
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
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing()) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
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
            val dialog = queue.pollFirst()
            dialog.show()
        }
    }
}