/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.notification

import android.content.Context
import android.content.Intent
import com.bitmark.fbm.feature.main.MainActivity
import com.onesignal.OSNotificationOpenResult
import com.onesignal.OneSignal
import javax.inject.Inject


class NotificationOpenedHandler @Inject constructor(private val context: Context) :
    OneSignal.NotificationOpenedHandler {

    override fun notificationOpened(result: OSNotificationOpenResult?) {
        val event = result?.notification?.payload?.additionalData?.getString("event")
        if (event.isNullOrBlank() || event != "fb_archive_available") return

        val intent = Intent(context, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        context.startActivity(intent)
    }
}