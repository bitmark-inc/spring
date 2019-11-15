/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.util.ext

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import com.bitmark.synergy.feature.Navigator
import com.bitmark.synergy.feature.Navigator.Companion.NONE

fun Navigator.gotoSecuritySetting() {
    val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
    anim(Navigator.BOTTOM_UP).startActivity(intent)
}

fun Navigator.openBrowser(url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        startActivity(intent)
    } catch (ignore: Throwable) {

    }
}

fun Navigator.openAppSetting(context: Context) {
    try {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", context.packageName, null)
        intent.data = uri
        startActivity(intent)
    } catch (ignore: Throwable) {
    }
}

fun Navigator.openMail(
    context: Context,
    email: String
) {
    try {
        val intent =
            Intent(Intent.ACTION_SENDTO, Uri.fromParts("mailto", email, null))
        intent.putExtra(Intent.EXTRA_EMAIL, arrayOf(email))
        startActivity(
                Intent.createChooser(
                        intent,
                        "send to %s".format(email)
                )
        )
    } catch (ignore: Throwable) {
    }
}

fun Navigator.browseMedia(
    mime: String,
    requestCode: Int
) {
    val intent = Intent(Intent.ACTION_PICK)
    when (mime) {
        "image/*" -> {
            intent.setDataAndType(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    mime
            )
        }

        "video/*" -> {
            intent.setDataAndType(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    mime
            )
        }
    }
    anim(NONE).startActivityForResult(intent, requestCode)
}

fun Navigator.browseDocument(requestCode: Int) {
    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
    intent.addCategory(Intent.CATEGORY_OPENABLE)
    intent.type = "*/*"
    anim(NONE).startActivityForResult(intent, requestCode)
}