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
import org.json.JSONObject
import javax.inject.Inject


class AppRemoteDataSource @Inject constructor(
    fbmApi: FbmApi,
    converter: Converter,
    rxErrorHandlingComposer: RxErrorHandlingComposer
) : RemoteDataSource(fbmApi, converter, rxErrorHandlingComposer) {

    fun registerNotificationService(tags: Map<String, String>) = Completable.fromCallable {
        val jsonObject = JSONObject()
        for (entry in tags.entries) {
            jsonObject.put(entry.key, entry.value)
        }
        OneSignal.sendTags(jsonObject)
    }.subscribeOn(Schedulers.io())

    fun getAutomationScript() = fbmApi.getAutomationScript().subscribeOn(Schedulers.io())
}