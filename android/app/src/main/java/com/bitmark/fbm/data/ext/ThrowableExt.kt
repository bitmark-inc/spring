/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.ext

import androidx.room.EmptyResultSetException
import com.bitmark.fbm.data.source.remote.api.error.HttpException
import com.bitmark.fbm.data.source.remote.api.error.NetworkException
import com.bitmark.fbm.data.source.remote.api.error.UnknownException
import java.io.IOException

fun Throwable.isNetworkError() = this is IOException

fun Throwable.isDbRecNotFoundError() = this is EmptyResultSetException

fun Throwable.isHttpError() =
    this is com.bitmark.apiservice.utils.error.HttpException || this is retrofit2.HttpException

fun Throwable.toRemoteError() = when {
    isNetworkError() -> NetworkException(this)
    isHttpError()    -> {
        val code = when (this) {
            is com.bitmark.apiservice.utils.error.HttpException -> statusCode
            is retrofit2.HttpException                          -> code()
            else                                                -> -1
        }
        val message = when (this) {
            is com.bitmark.apiservice.utils.error.HttpException -> "error: $errorMessage, reason: $reason"
            is retrofit2.HttpException                          -> message()
            else                                                -> message ?: ""
        }
        HttpException(code, message)
    }
    else             -> UnknownException(this)
}