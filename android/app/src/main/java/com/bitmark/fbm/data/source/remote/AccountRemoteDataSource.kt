/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.source.local.Jwt
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.request.ArchiveRequestPayload
import com.bitmark.fbm.data.source.remote.api.request.RegisterJwtRequest
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.intercom.android.sdk.Intercom
import io.intercom.android.sdk.identity.Registration
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject


class AccountRemoteDataSource @Inject constructor(
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun registerFbmServerJwt(
        timestamp: String,
        signature: String,
        requester: String
    ): Completable {
        return fbmApi.registerJwt(
            RegisterJwtRequest(
                timestamp,
                signature,
                requester
            )
        ).map { jwt ->
            val jwtCache = Jwt.getInstance()
            jwtCache.token = jwt.token
            jwtCache.expiredAt = System.currentTimeMillis() + jwt.expiredIn * 1000
        }.ignoreElement().subscribeOn(Schedulers.io())
    }

    fun registerFbmServerAccount(encPubKey: String): Single<AccountData> {
        return fbmApi.registerAccount(mapOf("enc_pub_key" to encPubKey))
            .map { res -> res["result"] ?: error("invalid response") }
            .subscribeOn(Schedulers.io())
    }

    fun sendArchiveDownloadRequest(
        archiveUrl: String, cookie: String, startedAtSec: Long, endedAtSec: Long
    ): Completable {
        val payload = ArchiveRequestPayload(archiveUrl, cookie, startedAtSec, endedAtSec)
        return fbmApi.sendArchiveDownloadRequest(payload)
    }

    fun registerIntercomUser(id: String) = Completable.fromAction {
        val registration = Registration.create().withUserId(id)
        Intercom.client().registerIdentifiedUser(registration)
    }.subscribeOn(Schedulers.io())

    fun getArchives() =
        fbmApi.getArchives().map { res -> res["result"] ?: error("invalid response") }

    fun getAccountInfo() =
        fbmApi.getAccountInfo().map { res ->
            res["result"] ?: error("invalid get account info response")
        }

    fun updateMetadata(metadata: Map<String, String>): Single<AccountData> {
        val json = newGsonInstance().toJson(mapOf("metadata" to metadata))
        val reqBody = json.toRequestBody("application/json".toMediaTypeOrNull())
        return fbmApi.updateMetadata(reqBody)
            .map { res -> res["result"] ?: error("invalid response") }.subscribeOn(Schedulers.io())
    }
}