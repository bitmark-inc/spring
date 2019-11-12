/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.source.local.api

import android.content.Context
import android.content.SharedPreferences
import com.bitmark.synergy.BuildConfig
import com.google.gson.Gson
import kotlin.reflect.KClass

class SharedPrefGateway internal constructor(
    context: Context, private val gson: Gson
) {

    private val sharedPreferences: SharedPreferences =
        context.getSharedPreferences(
            BuildConfig.APPLICATION_ID, Context.MODE_PRIVATE
        )

    @Suppress("UNCHECKED_CAST")
    fun <T : Any> get(key: String, type: KClass<T>, default: Any? = null): T {
        return when (type) {
            String::class -> sharedPreferences.getString(
                key,
                default as? String ?: ""
            ) as T
            Boolean::class -> sharedPreferences.getBoolean(
                key,
                default as? Boolean ?: false
            ) as T
            Float::class -> sharedPreferences.getFloat(
                key,
                default as? Float ?: 0f
            ) as T
            Int::class -> sharedPreferences.getInt(
                key,
                default as? Int ?: 0
            ) as T
            Long::class -> sharedPreferences.getLong(
                key,
                default as? Long ?: 0
            ) as T
            else -> gson.fromJson(
                sharedPreferences.getString(key, ""), type.java
            )
        }
    }

    fun <T> put(key: String, data: T) {
        val editor = sharedPreferences.edit()
        when (data) {
            is String -> editor.putString(key, data as String)
            is Boolean -> editor.putBoolean(key, data as Boolean)
            is Float -> editor.putFloat(key, data as Float)
            is Int -> editor.putInt(key, data as Int)
            is Long -> editor.putLong(key, data as Long)
            else -> editor.putString(key, gson.toJson(data))
        }
        editor.apply()
    }

    fun clear() {
        sharedPreferences.edit().clear().apply()
    }
}