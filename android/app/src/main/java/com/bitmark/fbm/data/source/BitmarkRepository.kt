/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.apiservice.params.IssuanceParams
import com.bitmark.apiservice.params.RegistrationParams
import com.bitmark.fbm.data.source.remote.BitmarkRemoteDataSource


class BitmarkRepository(private val remoteDataSource: BitmarkRemoteDataSource) {

    fun listAsset( assetId: String) =
        remoteDataSource.listAsset( assetId)

    fun issueBitmark(params: IssuanceParams) = remoteDataSource.issueBitmark(params)

    fun registerAsset(params: RegistrationParams) = remoteDataSource.registerAsset(params)

    fun listIssuedBitmark(issuer: String, assetId: String) =
        remoteDataSource.listIssuedBitmark(issuer, assetId)

}