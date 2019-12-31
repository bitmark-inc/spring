/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.content.Context
import androidx.annotation.StyleRes
import androidx.appcompat.app.AlertDialog

open class TaggedAlertDialog(context: Context, val tag: String?, @StyleRes theme: Int = 0) :
    AlertDialog(context, theme)