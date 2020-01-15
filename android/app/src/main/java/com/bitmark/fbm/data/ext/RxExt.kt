/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.ext

import io.reactivex.Completable
import io.reactivex.Single

fun <T> Single<T>.onNetworkErrorReturn(data: T) = onErrorResumeNext { e ->
    if (e.isNetworkError()) {
        Single.just(data)
    } else {
        Single.error<T>(e)
    }
}

fun <T> Single<T>.onRemoteErrorReturn(data: T) = onErrorResumeNext { e ->
    if (e.isNetworkError() || e.isHttpError()) {
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
    if (e.isNetworkError()) {
        action()
    } else {
        Single.error<T>(e)
    }
}

fun Completable.onNetworkErrorComplete() = onErrorResumeNext { e ->
    if (e.isNetworkError()) {
        Completable.complete()
    } else {
        Completable.error(e)
    }
}