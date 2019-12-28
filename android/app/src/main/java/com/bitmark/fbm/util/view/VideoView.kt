/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import android.content.Context
import android.util.AttributeSet
import android.widget.RelativeLayout
import com.bitmark.fbm.R
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.load
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.visible
import kotlinx.android.synthetic.main.layout_video.view.*


class VideoView(context: Context, attrs: AttributeSet?, defStyleAttr: Int) :
    RelativeLayout(context, attrs, defStyleAttr) {

    constructor(context: Context) : this(context, null, 0)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    private lateinit var media: Media

    init {
        inflate(context, R.layout.layout_video, this)
    }

    fun showThumbnail(media: Media, error: () -> Unit) {
        this.media = media
        ivDefaultThumbnail.gone()
        ivPlayVideo.visible()
        ivVideoThumbnail.load(media.url, media.uri, error)
    }

    fun showDefaultThumbnail() {
        ivVideoThumbnail.setBackgroundColor(context.getColor(R.color.athens_gray))
        ivDefaultThumbnail.visible()
    }

    fun setPlayClickListener(listener: (Media) -> Unit) {
        ivPlayVideo.setSafetyOnclickListener { listener(media) }
    }
}

data class Media(val url: String, val uri: String)