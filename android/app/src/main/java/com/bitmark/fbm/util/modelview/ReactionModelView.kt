/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.model.entity.ReactionR
import com.bitmark.fbm.data.model.entity.timestamp


data class ReactionModelView(
    val timestamp: Long,

    val reaction: Reaction,

    val title: String
) : ModelView {

    companion object {
        fun newInstance(reactionR: ReactionR) =
            ReactionModelView(reactionR.timestamp, reactionR.reaction, reactionR.title)
    }
}

fun ReactionModelView.getDrawRes() = when (reaction) {
    Reaction.LIKE  -> R.drawable.ic_like
    Reaction.LOVE  -> R.drawable.ic_love
    Reaction.HAHA  -> R.drawable.ic_haha
    Reaction.WOW   -> R.drawable.ic_wow
    Reaction.SAD   -> R.drawable.ic_sad
    Reaction.ANGRY -> R.drawable.ic_angry
}