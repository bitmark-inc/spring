/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.logging

interface EventLogger {

    fun logEvent(
        event: Event,
        level: Level = Level.DEBUG,
        metadata: Map<String, String>? = null
    )

    fun logError(event: Event, error: Throwable?)
}