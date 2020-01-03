/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.auth

import android.app.Activity
import android.content.Context
import com.bitmark.cryptography.crypto.encoder.Hex.HEX
import com.bitmark.cryptography.crypto.encoder.Raw.RAW
import com.bitmark.fbm.AppLifecycleHandler
import com.bitmark.fbm.R
import com.bitmark.fbm.data.ext.onNetworkErrorComplete
import com.bitmark.fbm.data.model.AccountData
import com.bitmark.fbm.data.model.isValid
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.connectivity.ConnectivityHandler
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.*
import com.bitmark.sdk.authentication.KeyAuthenticationSpec
import com.bitmark.sdk.features.Account
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject

class FbmServerAuthentication @Inject constructor(
    private val context: Context,
    private val appLifecycleHandler: AppLifecycleHandler,
    private val connectivityHandler: ConnectivityHandler,
    private val accountRepo: AccountRepository,
    private val logger: EventLogger
) : AppLifecycleHandler.AppStateChangedListener,
    ConnectivityHandler.NetworkStateChangeListener {

    private val compositeDisposable = CompositeDisposable()

    private var isProcessing = false

    private var dialogController: DialogController? = null

    fun start() {
        appLifecycleHandler.addAppStateChangedListener(this)
        connectivityHandler.addNetworkStateChangeListener(this)
    }

    fun stop() {
        compositeDisposable.dispose()
        connectivityHandler.removeNetworkStateChangeListener(this)
        appLifecycleHandler.removeAppStateChangedListener(this)
    }

    override fun onForeground() {
        super.onForeground()
        if (isProcessing || dialogController?.isAuthRequiredShowing() == true) return
        checkJwtExpiry()
    }

    override fun onChange(connected: Boolean) {
        if (!connected || isProcessing || dialogController?.isAuthRequiredShowing() == true) return
        checkJwtExpiry()
    }

    private fun checkJwtExpiry() {
        compositeDisposable.add(accountRepo.checkJwtExpired().flatMap { expired ->
            if (expired) {
                accountRepo.getAccountData()
            } else {
                Single.just(AccountData.newEmptyInstance())
            }
        }.doOnSubscribe {
            isProcessing = true
        }.observeOn(AndroidSchedulers.mainThread()).subscribe { accountData, e ->
            isProcessing = false
            val activity = appLifecycleHandler.getRunningActivity() ?: return@subscribe
            dialogController = DialogController(activity)
            if (e == null && accountData.isValid()) {
                loadAccount(
                    activity,
                    accountData.id,
                    accountData.keyAlias,
                    dialogController!!,
                    { account ->
                        refreshJwt(account, dialogController!!)
                    },
                    { throwable ->
                        logger.logError(Event.ACCOUNT_LOAD_KEY_STORE_ERROR, throwable)
                        dialogController?.unexpectedAlert { Navigator(activity).exitApp() }
                    })
            }
        })
    }

    private fun refreshJwt(account: Account, dialogController: DialogController) {
        compositeDisposable.add(
            Single.fromCallable {
                val requester = account.accountNumber
                val timestamp = System.currentTimeMillis().toString()
                val signature = HEX.encode(account.sign(RAW.decode(timestamp)))
                Triple(timestamp, signature, requester)
            }.subscribeOn(Schedulers.computation()).flatMapCompletable { t ->
                accountRepo.registerFbmServerJwt(t.first, t.second, t.third)
            }.retry(3).onNetworkErrorComplete().observeOn(AndroidSchedulers.mainThread())
                .subscribe({}, { e ->
                    if (e != null) {
                        logger.logError(Event.ACCOUNT_GET_JWT_ERROR, e)
                        dialogController.alert(e)
                    }
                })
        )
    }

    private fun loadAccount(
        activity: Activity,
        accountId: String,
        keyAlias: String,
        dialogController: DialogController,
        successAction: (Account) -> Unit,
        errorAction: (Throwable?) -> Unit
    ) {
        val spec =
            KeyAuthenticationSpec.Builder(context)
                .setAuthenticationDescription(context.getString(R.string.your_authorization_is_required))
                .setKeyAlias(keyAlias).build()
        val navigator = Navigator(activity)
        activity.loadAccount(
            accountId,
            spec,
            dialogController,
            successAction = successAction,
            setupRequiredAction = { navigator.gotoSecuritySetting() },
            canceledAction = {
                if (dialogController.isAuthRequiredShowing()) return@loadAccount
                dialogController.showAuthRequired {
                    loadAccount(
                        activity,
                        accountId,
                        keyAlias,
                        dialogController,
                        successAction,
                        errorAction
                    )
                }
            },
            invalidErrorAction = errorAction
        )
    }
}