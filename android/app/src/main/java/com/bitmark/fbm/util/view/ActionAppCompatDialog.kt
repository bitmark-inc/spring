/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.content.Context
import androidx.annotation.StringRes
import com.bitmark.fbm.R
import kotlinx.android.synthetic.main.layout_action_dialog.*


class ActionAppCompatDialog(
    context: Context,
    @StringRes
    private val title: Int,
    @StringRes
    private val message: Int,
    @StringRes
    private val actionText: Int,
    tag: String? = null,
    private val actionClickListener: () -> Unit = {}
) : BaseAppCompatDialog(context, tag) {

    override fun layoutRes(): Int = R.layout.layout_action_dialog

    override fun initComponents() {
        super.initComponents()

        setCancelable(false)
        tvTitle.text = context.getString(title)
        tvMessage.text = context.getString(message)
        btnAction.text = context.getString(actionText)
        btnAction.setOnClickListener { actionClickListener() }
    }
}