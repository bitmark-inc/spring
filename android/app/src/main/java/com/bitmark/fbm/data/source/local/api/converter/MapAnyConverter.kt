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


class MapAnyConverter {

    @TypeConverter
    fun fromMap(map: Map<String, Any>?) = if (map == null) {
        null
    } else {
        newGsonInstance().toJson(map)
    }

    @TypeConverter
    fun toMap(json: String?) = if (json.isNullOrEmpty()) {
        null
    } else {
        newGsonInstance().fromJson<Map<String, Any>>(json)
    }
}
