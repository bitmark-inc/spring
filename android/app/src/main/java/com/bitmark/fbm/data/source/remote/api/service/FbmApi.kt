/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.service

import com.bitmark.fbm.data.model.AppInfoData
import com.bitmark.fbm.data.model.ArchiveData
import com.bitmark.fbm.data.model.AutomationScriptData
import com.bitmark.fbm.data.model.JwtData
import com.bitmark.fbm.data.source.remote.api.request.ArchiveRequestPayload
import com.bitmark.fbm.data.source.remote.api.request.RegisterJwtRequest
import com.bitmark.fbm.data.source.remote.api.response.RegisterAccountResponse
import io.reactivex.Completable
import io.reactivex.Single
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST


interface FbmApi {

    @POST("api/accounts")
    fun registerAccount(@Body body: Map<String, String>): Single<RegisterAccountResponse>

    @POST("api/auth")
    fun registerJwt(@Body request: RegisterJwtRequest): Single<JwtData>

    @POST("api/archives")
    fun sendArchiveDownloadRequest(@Body payload: ArchiveRequestPayload): Completable

    @GET("assets/fb_automation.json")
    fun getAutomationScript(): Single<AutomationScriptData>

    @GET("api/information")
    fun getAppInfo(): Single<Map<String, AppInfoData>>

    @GET("api/archives")
    fun getArchives(): Single<Map<String, List<ArchiveData>>>
}