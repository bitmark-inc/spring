/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.apiservice.utils.callback.Callback1
import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.keymanagement.KeyManager
import com.bitmark.sdk.keymanagement.KeyManagerImpl
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName
import java.util.concurrent.Executor
import java.util.concurrent.Executors


data class CredentialData(
    @Expose
    @SerializedName("id")
    val id: String,

    @Expose
    @SerializedName("password")
    val password: String
) : Data {
    companion object {
        fun newInstance() = CredentialData("", "")
    }

    fun isValid() = id.isNotBlank() && password.isNotBlank()
}

fun CredentialData.save(
    activity: Activity,
    alias: String,
    executor: Executor = Executors.newSingleThreadExecutor(),
    callback: Callback0
) {
    executor.execute {
        val handler = Handler(Looper.getMainLooper())
        val keyManager = KeyManagerImpl(activity) as KeyManager
        val credential = newGsonInstance().toJson(this)
        val keyAuthSpec =
            KeyAuthenticationSpec.Builder(activity).setKeyAlias(alias)
                .setAuthenticationRequired(false)
                .build()
        keyManager.saveKey(
            alias,
            keyAuthSpec,
            credential.toByteArray(Charsets.UTF_8),
            object : Callback0 {
                override fun onSuccess() {
                    handler.post { callback.onSuccess() }
                }

                override fun onError(throwable: Throwable?) {
                    handler.post { callback.onError(throwable) }
                }

            }
        )
    }
}

fun CredentialData.Companion.load(
    activity: Activity,
    alias: String,
    executor: Executor = Executors.newSingleThreadExecutor(),
    callback: Callback1<CredentialData>
) {
    executor.execute {
        val handler = Handler(Looper.getMainLooper())
        val keyManager = KeyManagerImpl(activity) as KeyManager
        val keyAuthSpec =
            KeyAuthenticationSpec.Builder(activity).setKeyAlias(alias)
                .setAuthenticationRequired(false)
                .build()
        keyManager.getKey(alias, keyAuthSpec, object : Callback1<ByteArray> {
            override fun onSuccess(data: ByteArray?) {
                handler.post {
                    if (data == null) {
                        callback.onError(IllegalAccessException("credential is empty"))
                    } else {
                        val credential = newGsonInstance().fromJson<CredentialData>(String(data))
                        callback.onSuccess(credential)
                    }
                }
            }

            override fun onError(throwable: Throwable?) {
                handler.post {
                    callback.onError(throwable)
                }
            }

        })
    }
}