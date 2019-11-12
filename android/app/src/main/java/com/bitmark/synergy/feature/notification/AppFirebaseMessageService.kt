/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.feature.notification

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import com.bitmark.synergy.R
import com.bitmark.synergy.feature.main.MainActivity
import com.bitmark.synergy.util.ext.getResIdentifier
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject

class AppFirebaseMessageService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        if (isApplicationInForeground()) return

        val remoteNotification = remoteMessage.notification
        val title = remoteNotification?.title
        val body = remoteNotification?.body
        val icon = remoteNotification?.icon

        val bundle = Bundle()
        if (title != null) bundle.putString("title", title)
        if (body != null) bundle.putString("message", body)
        if (icon != null) bundle.putString("icon", icon)

        val entries = remoteMessage.data.entries

        for (entry in entries) {
            bundle.putString(entry.key, entry.value)
        }

        val data = try {
            JSONObject(bundle.getString("data", ""))
        } catch (e: Throwable) {
            null
        }

        if (data != null) {
            if (!bundle.containsKey("message")) {
                bundle.putString("message", data.optString("alert", null))
            }
            if (!bundle.containsKey("title")) {
                bundle.putString("title", data.optString("title", null))
            }
            if (!bundle.containsKey("sound")) {
                bundle.putString("soundName", data.optString("sound", null))
            }
            if (!bundle.containsKey("color")) {
                bundle.putString("color", data.optString("color", null))
            }

            val badge = data.optInt("badge", -1)
            if (badge > -1) {
                bundle.putInt("badge", badge)
            }
        }

        sendNotification(bundle)

    }

    private fun isApplicationInForeground(): Boolean {
        val activityManager =
            this.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val processes = activityManager.runningAppProcesses
        if (processes != null) {
            for (process in processes) {
                if (process.processName == application.packageName) {
                    if (process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                        for (d in process.pkgList) {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    private fun sendNotification(bundle: Bundle) {

        val context = applicationContext
        val intent = Intent(this, MainActivity::class.java)
        intent.putExtra("notification", bundle)
        intent.putExtra("direct_from_notification", true)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_ONE_SHOT
        )

        val channelName = getString(R.string.notification_channel_name)
        val notificationBuilder = NotificationCompat.Builder(this, channelName)
            .setContentTitle(bundle.getString("title", ""))
            .setContentText(bundle.getString("message"))
            .setAutoCancel(true)
            .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
            .setContentIntent(pendingIntent)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(bundle.getString("message"))
            )

        val icon =
            context.getResIdentifier(bundle.getString("icon", ""), "drawable")
        notificationBuilder.setSmallIcon(if (icon != null && icon > 0) icon else R.drawable.ic_notification)
        notificationBuilder.setLargeIcon(
            BitmapFactory.decodeResource(
                context.resources,
                if (icon != null && icon > 0) icon else R.drawable.ic_notification
            )
        )

        val color = try {
            Color.parseColor(bundle.getString("color", ""))
        } catch (e: Throwable) {
            null
        }
        if (color != null) notificationBuilder.color = color

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelName,
                channelName,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        notificationManager.notify(0, notificationBuilder.build())
    }

}