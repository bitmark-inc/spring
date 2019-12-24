/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName

@Entity(
    tableName = "Location",
    indices = [Index(
        value = ["address"]
    ), Index(value = ["id"], unique = true), Index(value = ["name"]), Index(value = ["coordinate"])]
)
data class LocationR(

    @Expose
    @SerializedName("id")
    @ColumnInfo(name = "id")
    @PrimaryKey(autoGenerate = true)
    val id: Long,

    @Expose
    @SerializedName("name")
    @ColumnInfo(name = "name")
    val name: String,

    @Expose
    @SerializedName("coordinate")
    @ColumnInfo(name = "coordinate")
    val coordinate: Coordinate?,

    @Expose
    @SerializedName("address")
    @ColumnInfo(name = "address")
    val address: String?,

    @Expose
    @SerializedName("url")
    @ColumnInfo(name = "url")
    val url: String?,

    @Expose
    @SerializedName("created_at")
    @ColumnInfo(name = "created_at")
    var createdAtSec: Long
)

val LocationR.createdAt: Long
    get() = createdAtSec * 1000

fun LocationR.applyCreatedAt(createdAtSec: Long) {
    this.createdAtSec = createdAtSec
}

data class Coordinate(
    @Expose
    @SerializedName("latitude")
    val lat: Double,

    @Expose
    @SerializedName("longitude")
    val lng: Double
) : Record