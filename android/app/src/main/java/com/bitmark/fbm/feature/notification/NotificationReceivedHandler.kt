/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.notification

import android.annotation.SuppressLint
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.logging.Tracer
import com.onesignal.OSNotification
import com.onesignal.OneSignal
import javax.inject.Inject


class NotificationReceivedHandler @Inject constructor(private val appRepo: AppRepository) :
    OneSignal.NotificationReceivedHandler {

    companion object {
        private const val TAG = "NotificationReceivedHandler"
    }

    @SuppressLint("CheckResult")
    override fun notificationReceived(notification: OSNotification?) {
        val event = notification?.payload?.additionalData?.getString("event")
        if (event.isNullOrBlank() || event != "fb_data_analyzed") return
        appRepo.setDataReady().subscribe({}, { e ->
            Tracer.ERROR.log(TAG, "setDataReady error: ${e.message ?: "unknown"}")
        })
    }
}