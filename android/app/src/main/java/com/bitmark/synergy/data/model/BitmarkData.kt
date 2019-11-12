/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.synergy.data.model

import androidx.room.Embedded
import com.bitmark.synergy.data.model.entity.BitmarkR

data class BitmarkData(
    @Embedded
    val bitmarkR: BitmarkR
) : Data