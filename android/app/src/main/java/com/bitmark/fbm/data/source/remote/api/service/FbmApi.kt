/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.service

import com.bitmark.fbm.data.model.*
import com.bitmark.fbm.data.model.entity.PostR
import com.bitmark.fbm.data.model.entity.ReactionR
import com.bitmark.fbm.data.model.entity.SectionR
import com.bitmark.fbm.data.source.remote.api.request.ArchiveRequestPayload
import com.bitmark.fbm.data.source.remote.api.request.RegisterJwtRequest
import io.reactivex.Completable
import io.reactivex.Single
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*


interface FbmApi {

    @POST("api/accounts")
    fun registerAccount(@Body body: Map<String, String>): Single<Map<String, AccountData>>

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

    @GET("api/usage/{period}")
    fun listUsage(
        @Path("period") period: String, @Query("started_at")
        startedAt: Long
    ): Single<Map<String, List<SectionR>>>

    @GET("api/insight")
    fun getInsight(): Single<Map<String, InsightData>>

    @GET("api/posts")
    fun listPost(
        @Query("started_at") startedAt: Long, @Query("ended_at")
        endedAt: Long
    ): Single<Map<String, List<PostR>>>

    @GET("api/reactions")
    fun listReaction(
        @Query("started_at") startedAt: Long, @Query("ended_at")
        endedAt: Long
    ): Single<Map<String, List<ReactionR>>>

    @GET("api/media")
    fun getPresignedUrl(@Query("key") uri: String): Single<Response<ResponseBody>>

    @GET("api/accounts/me")
    fun getAccountInfo(): Single<Map<String, AccountData>>

    @PATCH("api/accounts/me")
    fun updateMetadata(@Body body: RequestBody): Single<Map<String, AccountData>>
}