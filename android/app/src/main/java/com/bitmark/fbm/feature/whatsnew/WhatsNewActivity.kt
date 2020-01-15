/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.whatsnew

import android.graphics.Color
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.TextPaint
import android.text.method.LinkMovementMethod
import android.text.style.ClickableSpan
import android.view.View
import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.BOTTOM_UP
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.invisible
import com.bitmark.fbm.util.ext.openIntercom
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.activity_whats_new.*
import java.util.*
import javax.inject.Inject


class WhatsNewActivity : BaseAppCompatActivity() {

    companion object {

        private const val SUPPORT_EMAIL = "support@bitmark.com"

        private const val RE_ENTER = "re_enter"

        fun getBundle(reEnter: Boolean): Bundle {
            val bundle = Bundle()
            bundle.putBoolean(RE_ENTER, reEnter)
            return bundle
        }
    }

    @Inject
    internal lateinit var navigator: Navigator

    private var reEnter = false

    override fun layoutRes(): Int = R.layout.activity_whats_new

    override fun viewModel(): BaseViewModel? = null

    override fun initComponents() {
        super.initComponents()

        reEnter = intent?.extras?.getBoolean(RE_ENTER) ?: error("missing RE_ENTER")

        if (reEnter) {
            layoutToolbar.visible()
            btnContinue.invisible()
        } else {
            layoutToolbar.invisible()
            btnContinue.visible()
        }

        tvVersion.text = getString(R.string.version_format).format(BuildConfig.VERSION_NAME)

        val releaseNoteInfo =
            resources?.getStringArray(R.array.release_note_info) ?: arrayOf("", "")

        val releaseNote = releaseNoteInfo[0].format(SUPPORT_EMAIL)
        val spannable = SpannableString(releaseNote)
        val clickableSpan = object : ClickableSpan() {
            override fun onClick(widget: View) {
                navigator.openIntercom()
            }

            override fun updateDrawState(ds: TextPaint) {
                super.updateDrawState(ds)
                ds.isUnderlineText = false
            }

        }

        val startPos = releaseNote.indexOf(SUPPORT_EMAIL)
        spannable.setSpan(
            clickableSpan,
            startPos,
            startPos + SUPPORT_EMAIL.length,
            Spanned.SPAN_INCLUSIVE_EXCLUSIVE
        )
        tvNotes.text = spannable
        tvNotes.movementMethod = LinkMovementMethod.getInstance()
        tvNotes.setLinkTextColor(getColor(R.color.international_klein_blue))
        tvNotes.highlightColor = Color.TRANSPARENT

        tvDate.text = getString(R.string.day_ago_format).format(
            DateTimeUtil.dayCountFrom(
                DateTimeUtil.stringToDate(releaseNoteInfo[1]) ?: Date()
            )
        )

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }

        btnContinue.setOnClickListener {
            navigator.anim(BOTTOM_UP).finishActivityForResult()
        }
    }

    override fun onBackPressed() {
        if (reEnter) {
            navigator.anim(RIGHT_LEFT).finishActivity()
        } else {
            navigator.anim(BOTTOM_UP).finishActivityForResult()
        }
        super.onBackPressed()
    }
}