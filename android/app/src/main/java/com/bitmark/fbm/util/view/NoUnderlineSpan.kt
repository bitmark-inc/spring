/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.text.TextPaint
import android.text.style.UnderlineSpan


class NoUnderlineSpan : UnderlineSpan() {

    override fun updateDrawState(ds: TextPaint) {
        ds.isUnderlineText = false
    }
}