/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger

fun EventLogger.logSharedPrefError(throwable: Throwable?, prefix: String = "") {
    logError(Event.SHARE_PREF_ERROR, "$prefix: ${throwable?.message ?: "unknown"}")
}