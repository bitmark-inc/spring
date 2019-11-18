/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.model.entity.BitmarkR
import com.bitmark.fbm.data.source.local.api.converter.LinkedTreeMapConverter
import com.bitmark.fbm.data.source.local.api.dao.BitmarkDao

@Database(
    entities = [BitmarkR::class],
    version = 1
)
@TypeConverters(
    LinkedTreeMapConverter::class
)
abstract class DatabaseGateway : RoomDatabase() {

    companion object {
        const val DATABASE_NAME = BuildConfig.APPLICATION_ID
    }

    abstract fun bitmarkDao(): BitmarkDao

}