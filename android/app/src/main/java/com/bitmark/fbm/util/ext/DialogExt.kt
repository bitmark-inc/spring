/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import com.bitmark.fbm.R
import com.bitmark.fbm.feature.DialogController

fun DialogController.unexpectedAlert(action: () -> Unit = {}) =
    alert(
        R.string.error,
        R.string.unexpected_error,
        android.R.string.ok,
        false,
        clickEvent = action
    )