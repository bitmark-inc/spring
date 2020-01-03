/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.converter

import androidx.room.TypeConverter
import com.bitmark.fbm.data.model.entity.CriteriaType
import com.bitmark.fbm.data.model.entity.fromString
import com.bitmark.fbm.data.model.entity.value


class CriteriaTypeConverter {

    @TypeConverter
    fun fromCriteriaType(type: CriteriaType?) = type?.value

    @TypeConverter
    fun toCriteriaType(type: String?) =
        if (type.isNullOrEmpty()) null else CriteriaType.fromString(type)
}