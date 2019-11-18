/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import com.bitmark.fbm.data.source.remote.api.error.HttpException
import com.bitmark.fbm.data.source.remote.api.error.NetworkException

fun Throwable.isNetworkError() = this is NetworkException

fun Throwable.isHttpError() = this is HttpException