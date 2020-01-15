/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.logging

enum class Event(val value: String) {

    ACCOUNT_SAVE_TO_KEY_STORE_ERROR("account_save_to_keystore_error"),

    ACCOUNT_LOAD_KEY_STORE_ERROR("account_load_keystore_error"),

    ACCOUNT_SAVE_FB_CREDENTIAL_ERROR("account_save_fb_credential_error"),

    ACCOUNT_LOAD_FB_CREDENTIAL_ERROR("account_load_fb_credential_error"),

    ACCOUNT_UNLINK_ERROR("account_unlink_error"),

    ACCOUNT_SIGNIN_ERROR("sign_in_error"),

    ACCOUNT_GET_JWT_ERROR("account_get_jwt_error"),

    AUTOMATE_PAGE_DETECTION_ERROR("page_detection_error"),

    ARCHIVE_REQUEST_PREPARE_DATA_ERROR("archive_request_prepare_data_error"),

    ARCHIVE_REQUEST_REGISTER_ACCOUNT_ERROR("archive_request_register_account_error"),

    ARCHIVE_ISSUE_ERROR("archive_issue_error"),

    ARCHIVE_ISSUE_SUCCESS("archive_issue_success"),

    SPLASH_PREPARE_DATA_ERROR("splash_prepare_data_error"),

    SPLASH_VERSION_CHECK_ERROR("splash_version_check_error"),

    SHARE_PREF_ERROR("share_pref_error"),

    LOAD_STATISTIC_ERROR("statistic_error"),

    PLAY_VIDEO_ERROR("play_video_error"),

    INSIGHTS_LOADING_ERROR("insights_loading_error")
}