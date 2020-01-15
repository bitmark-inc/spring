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
import com.bitmark.cryptography.crypto.Sha3256
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.newGsonInstance
import com.bitmark.fbm.data.model.CredentialData.Companion.CREDENTIAL_ALIAS
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

        internal const val CREDENTIAL_ALIAS = "fb-credential"

        const val CREDENTIAL_FILE_NAME = "$CREDENTIAL_ALIAS.key"

        fun newInstance() = CredentialData("", "")
    }

    fun isValid() = id.isNotBlank() && password.isNotBlank()
}

fun CredentialData.Companion.hashId(id: String): String = HEX.encode(Sha3256.hash(RAW.decode(id)))

fun CredentialData.save(
    activity: Activity,
    executor: Executor = Executors.newSingleThreadExecutor(),
    success: () -> Unit,
    error: (Throwable?) -> Unit
) {
    executor.execute {
        val handler = Handler(Looper.getMainLooper())
        val keyManager = KeyManagerImpl(activity) as KeyManager
        val credential = newGsonInstance().toJson(this)
        val keyAuthSpec =
            KeyAuthenticationSpec.Builder(activity).setKeyAlias(CREDENTIAL_ALIAS)
                .setAuthenticationRequired(false)
                .build()
        keyManager.saveKey(
            CREDENTIAL_ALIAS,
            keyAuthSpec,
            credential.toByteArray(Charsets.UTF_8),
            object : Callback0 {
                override fun onSuccess() {
                    handler.post { success() }
                }

                override fun onError(throwable: Throwable?) {
                    handler.post { error(throwable) }
                }

            }
        )
    }
}

fun CredentialData.Companion.load(
    activity: Activity,
    executor: Executor = Executors.newSingleThreadExecutor(),
    success: (CredentialData) -> Unit,
    error: (Throwable?) -> Unit
) {
    executor.execute {
        val handler = Handler(Looper.getMainLooper())
        val keyManager = KeyManagerImpl(activity) as KeyManager
        val keyAuthSpec =
            KeyAuthenticationSpec.Builder(activity).setKeyAlias(CREDENTIAL_ALIAS)
                .setAuthenticationRequired(false)
                .build()
        keyManager.getKey(CREDENTIAL_ALIAS, keyAuthSpec, object : Callback1<ByteArray> {
            override fun onSuccess(data: ByteArray?) {
                handler.post {
                    if (data == null) {
                        error(IllegalAccessException("credential is empty"))
                    } else {
                        val credential = newGsonInstance().fromJson<CredentialData>(String(data))
                        success(credential)
                    }
                }
            }

            override fun onError(throwable: Throwable?) {
                handler.post {
                    error(throwable)
                }
            }

        })
    }
}