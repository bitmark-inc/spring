/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.middleware

import android.text.TextUtils
import com.bitmark.fbm.data.source.local.Jwt
import com.bitmark.fbm.logging.Tracer
import okhttp3.Response
import javax.inject.Inject


class FbmApiInterceptor @Inject constructor() : Interceptor() {

    override fun getTag(): String? = "FbmApiServer"

    override fun intercept(chain: okhttp3.Interceptor.Chain): Response {
        val builder = chain.request().newBuilder()
            .addHeader("Content-Type", "application/json")
            .addHeader("Accept", "application/json")
            .addHeader("Cache-Control", "no-cache")
            .addHeader("Cache-Control", "no-store")
        if (!TextUtils.isEmpty(Jwt.getInstance().token))
            builder.addHeader(
                "Authorization",
                "Bearer " + Jwt.getInstance().token
            )

        val req = builder.build()
        Tracer.INFO.log(getTag()!!, req.toString())
        val res = chain.proceed(req)
        Tracer.INFO.log(getTag()!!, res.toString())
        return res
    }
}