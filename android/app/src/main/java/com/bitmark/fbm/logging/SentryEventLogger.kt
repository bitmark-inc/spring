/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.logging

import android.os.Build
import com.bitmark.fbm.BuildConfig
import com.bitmark.fbm.data.source.AccountRepository
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.functions.BiFunction
import io.reactivex.schedulers.Schedulers
import io.sentry.Sentry
import io.sentry.event.EventBuilder
import io.sentry.event.UserBuilder
import io.sentry.event.interfaces.ExceptionInterface


class SentryEventLogger(private val accountRepo: AccountRepository) : EventLogger {
    private val compositeDisposable = CompositeDisposable()

    fun destroy() {
        compositeDisposable.dispose()
    }

    override fun logEvent(
        event: Event,
        level: Level,
        metadata: Map<String, String>?
    ) {
        val buildEventBuilderStream = buildBaseEventBuilder(
            event,
            io.sentry.event.Event.Level.INFO
        ).map { builder ->
            if (metadata != null) {
                for (entry in metadata.entries) {
                    builder.withExtra(entry.key, entry.value)
                }
            }
            builder
        }

        compositeDisposable.add(
            Single.zip(
                buildUserBuilder(),
                buildEventBuilderStream,
                BiFunction<UserBuilder, EventBuilder, Pair<UserBuilder, EventBuilder>> { user, event ->
                    Pair(
                        user,
                        event
                    )
                }).observeOn(AndroidSchedulers.mainThread())
                .subscribe { p, e ->
                    if (e == null) {
                        val context = Sentry.getContext()
                        context.user = p.first.build()
                        Sentry.capture(p.second.withLevel(level.toEventLevel()).build())
                    }
                }
        )
    }

    override fun logError(event: Event, error: Throwable?) {
        val buildEventBuilderStream = buildBaseEventBuilder(
            event,
            io.sentry.event.Event.Level.ERROR
        ).map { builder ->
            builder.withSentryInterface(
                ExceptionInterface(
                    error ?: UnknownError()
                )
            )
        }

        compositeDisposable.addAll(
            Single.zip(
                buildUserBuilder(),
                buildEventBuilderStream,
                BiFunction<UserBuilder, EventBuilder, Pair<UserBuilder, EventBuilder>> { user, event ->
                    Pair(
                        user,
                        event
                    )
                }).observeOn(AndroidSchedulers.mainThread())
                .subscribe { p, e ->
                    if (e == null) {
                        val context = Sentry.getContext()
                        context.user = p.first.build()
                        Sentry.capture(p.second.withLevel(io.sentry.event.Event.Level.ERROR).build())
                    }
                })
    }

    private fun buildBaseEventBuilder(
        event: Event,
        level: io.sentry.event.Event.Level
    ) = accountRepo.getAccountData().map { accountInfo ->
        val e = EventBuilder().withMessage(event.value).withLevel(level)
        e.withPlatform("Android")
        e.withEnvironment(BuildConfig.APPLICATION_ID)
        e.withRelease("${BuildConfig.APPLICATION_ID}-${BuildConfig.VERSION_NAME}")
        e.withDist("${BuildConfig.VERSION_CODE}")
        e.withExtra("os", "Android SDK ${Build.VERSION.SDK_INT}")
        e.withExtra("device", "${Build.MANUFACTURER}-${Build.MODEL}")
        e.withExtra("account_id", accountInfo.accountId)
        e.withExtra("auth_required_setup", accountInfo.authRequired)
    }.subscribeOn(Schedulers.computation())

    private fun buildUserBuilder() =
        accountRepo.getAccountData().map { accountInfo ->
            UserBuilder().setId(accountInfo.accountId)
        }

}