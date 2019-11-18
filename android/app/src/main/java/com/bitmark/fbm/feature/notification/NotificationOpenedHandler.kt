/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.notification

import com.onesignal.OSNotificationOpenResult
import com.onesignal.OneSignal
import javax.inject.Inject


class NotificationOpenedHandler @Inject constructor() : OneSignal.NotificationOpenedHandler {

    override fun notificationOpened(result: OSNotificationOpenResult?) {

    }
}