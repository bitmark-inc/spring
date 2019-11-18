/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.source.remote

import com.bitmark.synergy.data.source.remote.api.converter.Converter
import com.bitmark.synergy.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.synergy.data.source.remote.api.service.FbmApi

abstract class RemoteDataSource(
    protected val fbmApi: FbmApi,
    protected val converter: Converter,
    protected val rxErrorHandlingComposer: RxErrorHandlingComposer
)