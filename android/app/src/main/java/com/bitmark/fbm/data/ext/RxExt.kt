/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.ext

import com.bitmark.fbm.data.source.remote.api.error.HttpException
import com.bitmark.fbm.data.source.remote.api.error.NetworkException
import io.reactivex.Single

fun <T> Single<T>.onNetworkErrorReturn(data: T) = onErrorResumeNext { e ->
    if (e is NetworkException) {
        Single.just(data)
    } else {
        Single.error<T>(e)
    }
}

fun <T> Single<T>.onRemoteErrorReturn(data: T) = onErrorResumeNext { e ->
    if (e is NetworkException || e is HttpException) {
        Single.just(data)
    } else {
        Single.error<T>(e)
    }
}

fun <T> Single<T>.onIgnoreErrorReturn(data: T) = onErrorResumeNext { Single.just(data) }

fun <T> Single<T>.mapToCheckDbRecordResult() = map { true }.onErrorResumeNext { e ->
    if (e.isDbRecNotFoundError()) {
        Single.just(false)
    } else {
        Single.error(e)
    }
}

fun <T> Single<T>.onNetworkErrorResumeNext(action: () -> Single<T>) = onErrorResumeNext { e ->
    if (e is NetworkException) {
        action()
    } else {
        Single.error<T>(e)
    }
}