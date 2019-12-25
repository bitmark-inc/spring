/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view

import com.bumptech.glide.load.model.GlideUrl


class GlideUrlNoToken(url: String, private val cache: String?) : GlideUrl(url) {

    override fun getCacheKey(): String {
        return cache ?: super.getCacheKey()
    }
}