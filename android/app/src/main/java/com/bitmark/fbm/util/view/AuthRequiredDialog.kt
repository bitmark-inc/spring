/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.content.Context
import com.bitmark.fbm.R
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import kotlinx.android.synthetic.main.layout_dialog_auth_required.*


class AuthRequiredDialog(context: Context, tag: String? = null, private val action: () -> Unit) :
    BaseAppCompatDialog(context, tag) {

    override fun layoutRes(): Int = R.layout.layout_dialog_auth_required

    override fun initComponents() {
        super.initComponents()
        setCancelable(false)
        btnAuthorize.setSafetyOnclickListener { action() }
    }
}