/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source

import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.data.source.local.UsageLocalDataSource
import com.bitmark.fbm.data.source.remote.UsageRemoteDataSource


class UsageRepository(
    private val remoteDataSource: UsageRemoteDataSource,
    private val localDataSource: UsageLocalDataSource
) : Repository {

    fun getStatistic(period: Period) = remoteDataSource.getStatistic(period)

    fun getPost(type: PostType, from: Long, to: Long) = remoteDataSource.getPost(type, from, to)

}