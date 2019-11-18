/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.source.remote.api.service

import com.bitmark.synergy.data.model.JwtData
import com.bitmark.synergy.data.source.remote.api.request.ArchiveRequestPayload
import com.bitmark.synergy.data.source.remote.api.request.RegisterJwtRequest
import io.reactivex.Completable
import io.reactivex.Single
import retrofit2.http.Body
import retrofit2.http.POST


interface FbmApi {

    @POST("v1/account")
    fun registerAccount(): Single<Map<String, String>>

    @POST("v1/auth")
    fun registerJwt(@Body request: RegisterJwtRequest): Single<JwtData>

    @POST("v1/archive")
    fun sendArchiveDownloadRequest(@Body payload: ArchiveRequestPayload): Completable
}