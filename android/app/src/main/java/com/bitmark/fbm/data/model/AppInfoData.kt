/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class AppInfoData(
    @Expose
    @SerializedName("android")
    val androidAppInfo: AndroidAppInfo,

    @Expose
    @SerializedName("ios")
    val iosAppInfo: IosAppInfo,

    @Expose
    @SerializedName("server")
    val serverInfo: ServerInfo
) : Data

data class AndroidAppInfo(
    @Expose
    @SerializedName("minimum_client_version")
    val requiredVersion: Int
)

data class IosAppInfo(
    @Expose
    @SerializedName("minimum_client_version")
    val requiredVersion: String
)

data class ServerInfo(
    @Expose
    @SerializedName("version")
    val version: String
)