/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.converter

import androidx.room.TypeConverter
import com.bitmark.fbm.data.ext.fromJson
import com.bitmark.fbm.data.ext.newGsonInstance


class CollectionStringConverter {

    @TypeConverter
    fun fromCollection(collection: List<String>?) =
        if (collection == null || collection.isEmpty()) {
            null
        } else {
            newGsonInstance().toJson(collection)
        }

    @TypeConverter
    fun toCollection(json: String?) = if (json.isNullOrEmpty()) {
        null
    } else {
        newGsonInstance().fromJson<List<String>>(json)
    }

}