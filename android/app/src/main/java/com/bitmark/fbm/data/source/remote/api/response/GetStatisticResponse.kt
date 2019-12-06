/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.source.remote.api.response

import com.bitmark.fbm.data.model.entity.SectionR
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class GetStatisticResponse(
    @Expose
    @SerializedName("data")
    val sectionRs: List<SectionR>
) : Response