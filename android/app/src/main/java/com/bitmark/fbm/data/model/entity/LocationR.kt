/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Location",
    indices = [Index(
        value = ["address"]
    ), Index(value = ["name"], unique = true)]
)
data class LocationR(

    @Expose
    @SerializedName("name")
    @PrimaryKey
    val name: String,

    @Expose
    @SerializedName("coordinate")
    val coordinate: Coordinate?,

    @Expose
    @SerializedName("address")
    val address: String?,

    @Expose
    @SerializedName("url")
    val url: String?
)

data class Coordinate(
    @Expose
    @SerializedName("latitude")
    val lat: Double,

    @Expose
    @SerializedName("longitude")
    val lng: Double
) : Record