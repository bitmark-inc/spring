/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.modelview

import com.bitmark.fbm.data.model.entity.Coordinate
import com.bitmark.fbm.data.model.entity.LocationR
import com.bitmark.fbm.data.model.entity.createdAt


data class LocationModelView(
    val createdAt: Long,

    val name: String,

    val coordinate: Coordinate?
) : ModelView {

    companion object {
        fun newInstance(location: LocationR) =
            LocationModelView(location.createdAt, location.name, location.coordinate)
    }
}

fun LocationModelView.coordinateString() = if (coordinate == null) {
    ""
} else {
    "(%.7f %.7f)".format(coordinate.lat, coordinate.lng)
}