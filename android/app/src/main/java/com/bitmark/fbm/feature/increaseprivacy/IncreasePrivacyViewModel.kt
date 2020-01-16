/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.increaseprivacy

import androidx.lifecycle.Lifecycle
import com.bitmark.fbm.data.source.AppRepository
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.util.livedata.CompositeLiveData
import com.bitmark.fbm.util.livedata.RxLiveDataTransformer


class IncreasePrivacyViewModel(
    lifecycle: Lifecycle,
    private val appRepo: AppRepository,
    private val rxLiveDataTransformer: RxLiveDataTransformer
) : BaseViewModel(lifecycle) {

    internal val saveLinkClickedLiveData = CompositeLiveData<Any>()

    internal val listLinkClickedLiveData = CompositeLiveData<List<String>>()

    fun saveLinkClicked(link: String) {
        saveLinkClickedLiveData.add(rxLiveDataTransformer.completable(appRepo.saveLinkClicked(link)))
    }

    fun listLinkClicked() {
        listLinkClickedLiveData.add(rxLiveDataTransformer.single(appRepo.listLinkClicked()))
    }

}