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

fun Throwable.isNetworkError() = this is NetworkException

fun Throwable.isDbRecNotFoundError() = this is EmptyResultSetException

private fun Throwable.isHttpError() = this is HttpException

fun Throwable.toRemoteError() = when (this) {
    is IOException -> NetworkException(this)
    is com.bitmark.apiservice.utils.error.HttpException, is retrofit2.HttpException -> {
        val code = when (this) {
            is com.bitmark.apiservice.utils.error.HttpException -> statusCode
            is retrofit2.HttpException -> code()
            else -> -1
        }
        val message = when (this) {
            is com.bitmark.apiservice.utils.error.HttpException -> "error: $errorMessage, reason: $reason"
            is retrofit2.HttpException -> message()
            else -> message ?: ""
        }
        HttpException(code, message)
    }
    else -> UnknownException(this)
}

fun Throwable.isServiceUnsupportedError() = this is HttpException && this.code == 406