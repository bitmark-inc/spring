/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.fbm.data.source.local.Jwt
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.request.ArchiveRequestPayload
import com.bitmark.fbm.data.source.remote.api.request.RegisterJwtRequest
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import io.reactivex.Completable
import io.reactivex.Single
import io.reactivex.schedulers.Schedulers
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
            jwtCache.expiredAt = System.currentTimeMillis() + jwt.expiredIn
        }.ignoreElement().subscribeOn(Schedulers.io())
    }

    fun registerFbmServerAccount(): Single<String> {
        return fbmApi.registerAccount()
            .map { res -> res["account_id"] ?: error("invalid account id") }
            .subscribeOn(Schedulers.io())
    }

    fun sendArchiveDownloadRequest(
        accountId: String,
        fbId: String,
        fbPassword: String
    ): Completable {
        val payload = ArchiveRequestPayload(accountId, fbId, fbPassword)
        return fbmApi.sendArchiveDownloadRequest(payload)
    }
}