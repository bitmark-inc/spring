/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.apiservice.params.IssuanceParams
import com.bitmark.apiservice.params.RegistrationParams
import com.bitmark.apiservice.params.query.AssetQueryBuilder
import com.bitmark.apiservice.params.query.BitmarkQueryBuilder
import com.bitmark.apiservice.response.GetBitmarksResponse
import com.bitmark.apiservice.response.RegistrationResponse
import com.bitmark.apiservice.utils.callback.Callback1
import com.bitmark.apiservice.utils.record.AssetRecord
import com.bitmark.apiservice.utils.record.BitmarkRecord
import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import com.bitmark.sdk.features.Asset
import com.bitmark.sdk.features.Bitmark
import io.reactivex.SingleOnSubscribe
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class BitmarkRemoteDataSource @Inject constructor(
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun issueBitmark(params: IssuanceParams) =
        rxErrorHandlingComposer.single(SingleOnSubscribe<List<String>> { emt ->
            Bitmark.issue(params, object : Callback1<List<String>> {
                override fun onSuccess(data: List<String>?) {
                    emt.onSuccess(data!!)
                }

                override fun onError(throwable: Throwable?) {
                    emt.onError(throwable!!)
                }

            })
        }).subscribeOn(Schedulers.io())

    fun registerAsset(params: RegistrationParams) =
        rxErrorHandlingComposer.single(SingleOnSubscribe<String> { emt ->
            Asset.register(params, object : Callback1<RegistrationResponse> {
                override fun onSuccess(data: RegistrationResponse?) {
                    emt.onSuccess(data!!.assets.first().id)
                }

                override fun onError(throwable: Throwable?) {
                    emt.onError(throwable!!)
                }

            })
        }).subscribeOn(Schedulers.io())

    fun listAsset(assetId: String) =
        rxErrorHandlingComposer.single(SingleOnSubscribe<List<AssetRecord>> { emt ->
            val builder = AssetQueryBuilder().assetIds(arrayOf(assetId))
            Asset.list(builder, object : Callback1<List<AssetRecord>> {
                override fun onSuccess(data: List<AssetRecord>?) {
                    emt.onSuccess(data!!)
                }

                override fun onError(throwable: Throwable?) {
                    emt.onError(throwable!!)
                }
            })
        })

    fun listIssuedBitmark(issuer: String, assetId: String) =
        rxErrorHandlingComposer.single(SingleOnSubscribe<List<BitmarkRecord>> { emt ->
            val builder =
                BitmarkQueryBuilder().issuedBy(issuer).pending(true).referencedAsset(assetId)

            Bitmark.list(builder, object : Callback1<GetBitmarksResponse> {
                override fun onSuccess(data: GetBitmarksResponse?) {
                    emt.onSuccess(data!!.bitmarks)
                }

                override fun onError(throwable: Throwable?) {
                    emt.onError(throwable!!)
                }
            })
        })

}