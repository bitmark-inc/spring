/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import android.app.Activity
import android.content.Context.INPUT_METHOD_SERVICE
import android.view.inputmethod.InputMethodManager

fun Activity.hideKeyBoard() {
    val view = this.currentFocus
    if (null != view) {
        val inputManager =
            getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager
        inputManager?.hideSoftInputFromWindow(view.windowToken, 0)
    }

}

fun Activity.showKeyBoard() {
    val view = this.currentFocus
    if (null != view) {
        val inputManager =
            getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager
        inputManager?.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)
    }

}
