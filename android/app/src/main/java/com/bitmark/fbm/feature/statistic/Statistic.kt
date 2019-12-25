/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import androidx.annotation.StringDef

object Statistic {
    const val USAGE = "usage"

    const val INSIGHTS = "insights"

    @Retention(AnnotationRetention.SOURCE)
    @StringDef(USAGE, INSIGHTS)
    annotation class Type

}


