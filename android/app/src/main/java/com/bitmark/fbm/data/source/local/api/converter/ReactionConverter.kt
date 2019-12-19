/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.local.api.converter

import androidx.room.TypeConverter
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.fromString
import com.bitmark.fbm.data.model.entity.value


class ReactionConverter {

    @TypeConverter
    fun fromReaction(reaction: Reaction) = reaction.value

    @TypeConverter
    fun toReaction(reaction: String) = Reaction.fromString(reaction)
}