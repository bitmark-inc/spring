/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.logging

enum class Event(val value: String) {

    ACCOUNT_SAVE_TO_KEY_STORE_ERROR("account_save_to_keystore_error"),

    FB_ARCHIVE_AUTOMATE_PAGE_DETECTION_FAILED("fb_archive_automate_page_detection_failed"),

    ACCOUNT_SAVE_FB_CREDENTIAL_ERROR("account_save_fb_credential_error")
}