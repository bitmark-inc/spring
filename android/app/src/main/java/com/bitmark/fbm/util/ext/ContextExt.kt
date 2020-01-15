/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.annotation.DimenRes

fun Context.copyToClipboard(text: String) {
    val clipboardManager =
        getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("", text)
    clipboardManager.primaryClip = clip
}

fun Context.getResIdentifier(resName: String, classifier: String) = try {
    resources.getIdentifier(resName, classifier, packageName)
} catch (e: Throwable) {
    null
}

fun Context.getString(stringResName: String): String {
    val id = getResIdentifier(stringResName, "string") ?: return ""
    return try {
        getString(id)
    } catch (e: Throwable) {
        ""
    }
}

fun Context.getDimensionPixelSize(@DimenRes dimenRes: Int): Int {
    return try {
        resources.getDimensionPixelSize(dimenRes)
    } catch (e: Throwable) {
        0
    }
}

fun Context.getDimension(@DimenRes dimenRes: Int, default: Float = 0f): Float {
    return try {
        resources.getDimension(dimenRes)
    } catch (e: Throwable) {
        default
    }
}

fun Context.pxToDp(px: Float) = px / resources.displayMetrics.density

fun Context.dpToPx(dp: Int) = dp * resources.displayMetrics.density

fun Context.spToPx(sp: Int) = sp * resources.displayMetrics.scaledDensity

val Context.screenWidth: Int
    get() = resources.displayMetrics.widthPixels

