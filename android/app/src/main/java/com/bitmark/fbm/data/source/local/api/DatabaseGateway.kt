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
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.data.source.local.api.converter.*
import com.bitmark.fbm.data.source.local.api.dao.*

@Database(
    entities = [SectionR::class, PostR::class, CommentR::class, LocationR::class, ReactionR::class],
    version = 2
)
@TypeConverters(
    MapStringConverter::class,
    MapAnyConverter::class,
    PeriodConverter::class,
    SectionNameConverter::class,
    CollectionStringConverter::class,
    PostTypeConverter::class,
    CoordinateConverter::class,
    ReactionConverter::class,
    MediaDataConverter::class,
    CollectionLongConverter::class,
    FriendDataConverter::class
)
abstract class DatabaseGateway : RoomDatabase() {

    companion object {
        const val DATABASE_NAME = BuildConfig.APPLICATION_ID
    }

    abstract fun sectionDao(): SectionDao

    abstract fun postDao(): PostDao

    abstract fun commentDao(): CommentDao

    abstract fun locationDao(): LocationDao

    abstract fun reactionDao(): ReactionDao

}