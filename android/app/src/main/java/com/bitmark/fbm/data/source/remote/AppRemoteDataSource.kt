/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote

import com.bitmark.fbm.data.source.remote.api.converter.Converter
import com.bitmark.fbm.data.source.remote.api.middleware.RxErrorHandlingComposer
import com.bitmark.fbm.data.source.remote.api.service.FbmApi
import com.onesignal.OneSignal
import io.reactivex.Completable
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class AppRemoteDataSource @Inject constructor(
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun registerNotificationService(accountId: String) = Completable.fromCallable {
        OneSignal.deleteTag("account_id")
        OneSignal.sendTag("account_id", accountId)
    }.subscribeOn(Schedulers.io())

    fun getAutomationScript() = fbmApi.getAutomationScript().subscribeOn(Schedulers.io())

    fun getAppInfo() = fbmApi.getAppInfo().map { res ->
        res["information"] ?: error("could not get app info")
    }
}