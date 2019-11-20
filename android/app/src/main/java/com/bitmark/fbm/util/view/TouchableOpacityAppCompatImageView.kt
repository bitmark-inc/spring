/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import androidx.appcompat.widget.AppCompatImageView


class TouchableOpacityAppCompatImageView(
    context: Context,
    attrs: AttributeSet?,
    defStyleAttr: Int
) :
    AppCompatImageView(context, attrs, defStyleAttr) {

    init {
        isClickable = true
        isFocusable = true
    }

    constructor(context: Context, attrs: AttributeSet) : this(context, attrs, 0)

    constructor(context: Context) : this(context, null, 0)

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        when (event?.action) {
            MotionEvent.ACTION_DOWN -> {
                alpha = 0.5f
            }

            MotionEvent.ACTION_UP   -> {
                alpha = 1.0f
            }
        }
        return super.onTouchEvent(event)
    }
}