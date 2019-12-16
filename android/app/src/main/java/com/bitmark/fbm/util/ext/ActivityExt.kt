/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.ext

import android.app.Activity
import android.content.Context.INPUT_METHOD_SERVICE
import android.view.inputmethod.InputMethodManager
import com.bitmark.apiservice.utils.callback.Callback0
import com.bitmark.apiservice.utils.callback.Callback1
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.DialogController
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.authentication.Provider
import com.bitmark.sdk.authentication.error.AuthenticationException
import com.bitmark.sdk.authentication.error.AuthenticationRequiredException
import com.bitmark.sdk.features.Account

fun Activity.hideKeyBoard() {
    val view = this.currentFocus
    if (null != view) {
        val inputManager =
            getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager
        inputManager?.hideSoftInputFromWindow(view.windowToken, 0)
    }

}

fun Activity.showKeyBoard() {
    val view = this.currentFocus
    if (null != view) {
        val inputManager =
            getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager
        inputManager?.showSoftInput(view, InputMethodManager.SHOW_IMPLICIT)
    }

}

fun Activity.loadAccount(
    accountNumber: String,
    spec: KeyAuthenticationSpec,
    dialogController: DialogController,
    successAction: (Account) -> Unit,
    canceledAction: () -> Unit = {},
    setupRequiredAction: () -> Unit = {},
    invalidErrorAction: (Throwable?) -> Unit = {}
) {
    Account.loadFromKeyStore(
        this,
        accountNumber,
        spec,
        object : Callback1<Account> {
            override fun onSuccess(acc: Account?) {
                successAction.invoke(acc!!)
            }

            override fun onError(throwable: Throwable?) {
                when (throwable) {

                    // authentication error
                    is AuthenticationException         -> {
                        when (throwable.type) {
                            // action cancel authentication
                            AuthenticationException.Type.CANCELLED -> {
                                canceledAction.invoke()
                            }

                            else                                   -> {
                                // do nothing
                            }
                        }
                    }

                    // missing security requirement
                    is AuthenticationRequiredException -> {
                        when (throwable.provider) {

                            // did not set up fingerprint/biometric
                            Provider.FINGERPRINT, Provider.BIOMETRIC -> {
                                dialogController.alert(
                                    R.string.error,
                                    R.string.fingerprint_required
                                ) { setupRequiredAction.invoke() }
                            }

                            // did not set up pass code
                            else                                     -> {
                                dialogController.alert(
                                    R.string.error,
                                    R.string.passcode_pin_required
                                ) { setupRequiredAction.invoke() }
                            }
                        }
                    }
                    else                               -> {
                        invalidErrorAction.invoke(throwable)
                    }
                }
            }

        })
}

fun Activity.removeAccount(
    accountNumber: String,
    spec: KeyAuthenticationSpec,
    dialogController: DialogController,
    successAction: () -> Unit,
    canceledAction: () -> Unit = {},
    setupRequiredAction: () -> Unit = {},
    invalidErrorAction: (Throwable?) -> Unit = {}
) {
    Account.removeFromKeyStore(this, accountNumber, spec, object : Callback0 {
        override fun onSuccess() {
            successAction.invoke()
        }

        override fun onError(throwable: Throwable?) {
            when (throwable) {

                // authentication error
                is AuthenticationException         -> {
                    when (throwable.type) {
                        // action cancel authentication
                        AuthenticationException.Type.CANCELLED -> {
                            canceledAction.invoke()
                        }

                        else                                   -> {
                            // do nothing
                        }
                    }
                }

                // missing security requirement
                is AuthenticationRequiredException -> {
                    when (throwable.provider) {

                        // did not set up fingerprint/biometric
                        Provider.FINGERPRINT, Provider.BIOMETRIC -> {
                            dialogController.alert(
                                R.string.error,
                                R.string.fingerprint_required
                            ) { setupRequiredAction.invoke() }
                        }

                        // did not set up pass code
                        else                                     -> {
                            dialogController.alert(
                                R.string.error,
                                R.string.passcode_pin_required
                            ) { setupRequiredAction.invoke() }
                        }
                    }
                }
                else                               -> {
                    invalidErrorAction.invoke(throwable)
                }
            }
        }

    })
}
