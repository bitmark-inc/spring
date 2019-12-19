/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.reactiondetail

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.model.entity.Reaction
import com.bitmark.fbm.data.source.UsageRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer
import com.bitmark.fbm.util.modelview.ReactionModelView
import io.reactivex.Single


class ReactionDetailViewModel(
    lifecycle: Lifecycle,
    private val usageRepo: UsageRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val listReactionLiveData = CompositeLiveData<List<ReactionModelView>>()

    private var lastEndedAtSec = -1L

    fun listReaction(startedAtSec: Long, endedAtSec: Long) {
        listReactionLiveData.add(
            rxLiveDataTransformer.single(
                listReactionStream(
                    startedAtSec,
                    endedAtSec
                )
            )
        )
    }

    fun listNextReaction(startedAtSec: Long) {
        listReactionLiveData.add(
            rxLiveDataTransformer.single(
                listReactionStream(
                    startedAtSec,
                    lastEndedAtSec - 1
                )
            )
        )
    }

    private fun listReactionStream(
        startedAtSec: Long,
        endedAtSec: Long
    ): Single<List<ReactionModelView>> =
        usageRepo.listReaction(
            startedAtSec,
            endedAtSec
        ).map { reactions ->
            if (reactions.isNotEmpty()) {
                lastEndedAtSec = reactions.last().timestampSec
            }
            reactions.map { r -> ReactionModelView.newInstance(r) }
        }

    fun listReactionByType(reaction: Reaction, startedAtSec: Long, endedAtSec: Long) {
        listReactionLiveData.add(
            rxLiveDataTransformer.single(
                listReactionStreamByType(
                    reaction,
                    startedAtSec,
                    endedAtSec
                )
            )
        )
    }

    fun listNextReactionByType(reaction: Reaction, startedAtSec: Long) {
        listReactionLiveData.add(
            rxLiveDataTransformer.single(
                listReactionStreamByType(
                    reaction,
                    startedAtSec,
                    lastEndedAtSec - 1
                )
            )
        )
    }

    private fun listReactionStreamByType(
        reaction: Reaction,
        startedAtSec: Long,
        endedAtSec: Long
    ): Single<List<ReactionModelView>> =
        usageRepo.listReactionByType(
            reaction,
            startedAtSec,
            endedAtSec
        ).map { reactions ->
            if (reactions.isNotEmpty()) {
                lastEndedAtSec = reactions.last().timestampSec
            }
            reactions.map { r -> ReactionModelView.newInstance(r) }
        }
}