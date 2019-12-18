/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.data.model

import com.google.gson.annotations.Expose
import com.google.gson.annotations.SerializedName


data class AutomationScriptData(
    @Expose
    @SerializedName("pages")
    val pages: List<Page>
) : Data {

    fun getPage(name: Page.Name) = pages.find { p -> p.name == name }

    fun getLoginScript(fbId: String, fbPassword: String) =
        getPage(Page.Name.LOGIN)?.actions?.get("login")?.replace(
            "%username%",
            fbId
        )?.replace("%password%", fbPassword)

    fun getCheckLoginFailedScript() = getPage(Page.Name.LOGIN)?.actions?.get("isLogInFailed")

    fun getSaveDeviceNotNowScript() = getPage(Page.Name.SAVE_DEVICE)?.actions?.get("notNow")

    fun getSaveDeviceOkScript() = getPage(Page.Name.SAVE_DEVICE)?.actions?.get("ok")

    fun getNewFeedGoToSettingPageScript() =
        getPage(Page.Name.NEW_FEED)?.actions?.get("goToSettingsPage")

    fun getNewFeedGoToArchivePageScript() =
        getPage(Page.Name.NEW_FEED)?.actions?.get("goToArchivePage")

    fun getSettingGoToArchivePageScript() =
        getPage(Page.Name.SETTINGS)?.actions?.get("goToArchivePage")

    fun getArchiveSelectRequestTabScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("selectRequestTab")

    fun getArchiveSelectDownloadTabScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("selectDownloadTab")

    fun getArchiveSelectJsonOptionScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("selectJSONOption")

    fun getArchiveSelectHighResolution() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("selectHighResolutionOption")

    fun getArchiveSetFromTimestampScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("setFromTimestamp")

    fun getArchiveCreateFileScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("createFile")

    fun getArchiveCreatingFileScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("isCreatingFile")

    fun getArchiveDownloadFirstFileScript() =
        getPage(Page.Name.ARCHIVE)?.actions?.get("downloadFirstFile")

    fun getReAuthScript(password: String) =
        getPage(Page.Name.RE_AUTH)?.actions?.get("reauth")?.replace("%password%", password)

}

data class Page(
    @Expose
    @SerializedName("name")
    val name: Name,

    @Expose
    @SerializedName("detection")
    val detection: String,

    @Expose
    @SerializedName("actions")
    val actions: Map<String, String>
) {
    enum class Name {
        @Expose
        @SerializedName("login")
        LOGIN,

        @Expose
        @SerializedName("account_picking")
        ACCOUNT_PICKING,

        @Expose
        @SerializedName("save_device")
        SAVE_DEVICE,

        @Expose
        @SerializedName("new_feed")
        NEW_FEED,

        @Expose
        @SerializedName("settings")
        SETTINGS,

        @Expose
        @SerializedName("archive")
        ARCHIVE,

        @Expose
        @SerializedName("reauth")
        RE_AUTH,

        @Expose
        @SerializedName("unknown")
        UNKNOWN;

        companion object

    }
}

val Page.Name.value: String
    get() = when (this) {
        Page.Name.LOGIN           -> "login"
        Page.Name.ACCOUNT_PICKING -> "account_picking"
        Page.Name.SAVE_DEVICE     -> "save_device"
        Page.Name.NEW_FEED        -> "new_feed"
        Page.Name.SETTINGS        -> "settings"
        Page.Name.ARCHIVE         -> "archive"
        Page.Name.RE_AUTH         -> "reauth"
        Page.Name.UNKNOWN         -> "unknown"
    }

fun Page.Name.Companion.fromString(name: String) = when (name) {
    "login"           -> Page.Name.LOGIN
    "account_picking" -> Page.Name.ACCOUNT_PICKING
    "save_device"     -> Page.Name.SAVE_DEVICE
    "new_feed"        -> Page.Name.NEW_FEED
    "settings"        -> Page.Name.SETTINGS
    "archive"         -> Page.Name.ARCHIVE
    "reauth"          -> Page.Name.RE_AUTH
    else              -> Page.Name.UNKNOWN
}

