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
import androidx.appcompat.app.AppCompatDialog
import com.bitmark.fbm.R
import com.bitmark.fbm.util.view.TaggedAlertDialog
import java.util.*

class DialogController(internal val activity: Activity) {

    private val queue = ArrayDeque<TaggedAlertDialog>()

    var showingDialog: AppCompatDialog? = null
        private set

    private fun dismissListener(forwarder: () -> Unit = {}) =
        DialogInterface.OnDismissListener {
            showingDialog = null
            forwarder()
        }

    fun isShowing() = showingDialog != null

    fun show(dialog: TaggedAlertDialog, dismissCallback: () -> Unit = {}) {
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (isShowing() && dialog != showingDialog) {
            queue.add(dialog)
        } else {
            dialog.show()
            showingDialog = dialog
        }
    }

    fun dismiss(dialog: TaggedAlertDialog, dismissCallback: () -> Unit = {}) {
        dialog.setOnDismissListener(dismissListener {
            dismissCallback()
            showNext()
        })
        dialog.dismiss()
    }

    fun alert(
        throwable: Throwable?,
        cancelable: Boolean = false,
        tag: String? = null,
        clickEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        alert(
            activity.getString(R.string.error),
            throwable?.message ?: "Unknown error",
            activity.getString(android.R.string.ok),
            cancelable,
            tag,
            clickEvent,
            dismissCallback
        )
    }

    fun alert(
        title: String,
        message: String,
        text: String = activity.getString(android.R.string.ok),
        cancelable: Boolean = false,
        tag: String? = null,
        clickEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        val dialog = TaggedAlertDialog(activity, tag)
        dialog.setTitle(title)
        dialog.setMessage(message)
        dialog.setButton(
            DialogInterface.BUTTON_POSITIVE, text
        ) { d, _ ->
            d.dismiss()
            clickEvent()
            showNext()
        }
        dialog.setCancelable(cancelable)
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (!isShowing()) {
            dialog.show()
            showingDialog = dialog
        } else if (!queue.has(dialog)) {
            queue.add(dialog)
        }
    }

    fun alert(
        @StringRes title: Int,
        @StringRes message: Int,
        @StringRes text: Int = android.R.string.ok,
        cancelable: Boolean = false,
        tag: String? = null,
        clickEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        alert(
            activity.getString(title),
            activity.getString(message),
            activity.getString(text),
            cancelable,
            tag,
            clickEvent,
            dismissCallback
        )
    }

    fun confirm(
        title: String,
        message: String,
        cancelable: Boolean = false,
        tag: String? = null,
        positive: String = activity.getString(android.R.string.ok),
        positiveEvent: () -> Unit = {},
        negative: String = activity.getString(android.R.string.cancel),
        negativeEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        val dialog = TaggedAlertDialog(activity, tag)
        dialog.setTitle(title)
        dialog.setMessage(message)
        dialog.setButton(
            DialogInterface.BUTTON_POSITIVE, positive
        ) { d, _ ->
            d.dismiss()
            positiveEvent()
            showNext()
        }
        dialog.setButton(
            DialogInterface.BUTTON_NEGATIVE, negative
        ) { d, _ ->
            d.dismiss()
            negativeEvent()
        }
        dialog.setCancelable(cancelable)
        dialog.setOnDismissListener(dismissListener(dismissCallback))
        if (!isShowing()) {
            dialog.show()
            showingDialog = dialog
        } else if (!queue.has(dialog)) {
            queue.add(dialog)
        }
    }

    fun confirm(
        @StringRes title: Int,
        @StringRes message: Int,
        cancelable: Boolean = false,
        tag: String? = null,
        @StringRes positive: Int = android.R.string.ok,
        positiveEvent: () -> Unit = {},
        @StringRes negative: Int = android.R.string.cancel,
        negativeEvent: () -> Unit = {},
        dismissCallback: () -> Unit = {}
    ) {
        confirm(
            activity.getString(title),
            activity.getString(message),
            cancelable,
            tag,
            activity.getString(positive),
            positiveEvent,
            activity.getString(negative),
            negativeEvent,
            dismissCallback
        )
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

fun ArrayDeque<TaggedAlertDialog>.has(dialog: TaggedAlertDialog) =
    this.indexOfFirst { d -> d.tag != null && d.tag == dialog.tag } != -1