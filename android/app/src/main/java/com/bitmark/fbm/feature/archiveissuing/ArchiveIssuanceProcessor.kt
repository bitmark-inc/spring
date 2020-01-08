/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.archiveissuing

import android.util.Log
import com.bitmark.apiservice.params.IssuanceParams
import com.bitmark.apiservice.params.RegistrationParams
import com.bitmark.fbm.data.model.assetId
import com.bitmark.fbm.data.model.hashBytes
import com.bitmark.fbm.data.model.metaData
import com.bitmark.fbm.data.source.AccountRepository
import com.bitmark.fbm.data.source.BitmarkRepository
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Level
import com.bitmark.fbm.util.ext.flatten
import com.bitmark.sdk.features.Account
import io.reactivex.Single
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.exceptions.CompositeException
import io.reactivex.functions.BiConsumer
import io.reactivex.schedulers.Schedulers
import javax.inject.Inject


class ArchiveIssuanceProcessor @Inject constructor(
    private val bitmarkRepo: BitmarkRepository,
    private val accountRepo: AccountRepository,
    private val logger: EventLogger
) {

    companion object {
        private const val TAG = "ArchiveIssuance"
    }

    private val disposeBag = CompositeDisposable()

    fun start(account: Account) {
        if (disposeBag.isDisposed) error("cannot restart the stopped one")
        disposeBag.add(startIssuingStream(account).subscribe({ bitmarkIds ->
            if (bitmarkIds.isEmpty()) return@subscribe
            logger.logEvent(
                Event.ARCHIVE_ISSUE_SUCCESS,
                Level.INFO,
                mapOf("bitmark_ids" to bitmarkIds.joinToString(","))
            )
        }, { e ->
            if (e is CompositeException) {
                e.exceptions.forEach {
                    Log.e(TAG, e.message)
                    logger.logError(Event.ARCHIVE_ISSUE_ERROR, it)
                }
            } else {
                Log.e(TAG, e.message)
                logger.logError(Event.ARCHIVE_ISSUE_ERROR, e)
            }
        }))
    }

    fun stop() {
        disposeBag.dispose()
    }

    private fun startIssuingStream(account: Account) =
        accountRepo.listProcessedArchive().flatMap { archives ->

            // filter the asset id has not been issued
            val assetIds = archives.map { a -> a.assetId }

            val streams = assetIds.map { assetId ->
                val checkIssuedBm =
                    fun(aId: String) = bitmarkRepo.listIssuedBitmark(
                        account.accountNumber,
                        aId
                    ).map { bms -> Pair(aId, bms.isNotEmpty()) }
                checkIssuedBm(assetId)
            }

            Single.merge(streams).collectInto(
                mutableListOf(),
                BiConsumer<MutableList<Pair<String, Boolean>>, Pair<String, Boolean>> { result, data ->
                    result.add(data)
                }).map { result -> result.filter { !it.second }.map { it.first } }
                .map { hasNotIssuedAssetIds ->
                    Pair(hasNotIssuedAssetIds, archives)
                }
        }.observeOn(Schedulers.io()).flatMap { p ->

            // filter the asset id has not been registered
            val hasNotIssuedAssetIds = p.first
            val archives = p.second

            if (hasNotIssuedAssetIds.isEmpty()) {
                Single.just(Triple(hasNotIssuedAssetIds, listOf(), archives))
            } else {
                val streams = hasNotIssuedAssetIds.map { assetId ->
                    val checkRegisteredAsset = fun(aId: String) =
                        bitmarkRepo.listAsset(aId).map { assets ->
                            Pair(aId, assets.isNotEmpty())
                        }
                    checkRegisteredAsset(assetId)
                }

                Single.merge(streams).collectInto(
                    mutableListOf(),
                    BiConsumer<MutableList<Pair<String, Boolean>>, Pair<String, Boolean>> { collection, data ->
                        collection.add(data)
                    }).map { result -> result.filter { !it.second }.map { it.first } }
                    .map { unregisteredAssetIds ->
                        Triple(
                            hasNotIssuedAssetIds,
                            unregisteredAssetIds,
                            archives
                        )
                    }
            }
        }.observeOn(Schedulers.io()).flatMap { t ->
            val hasNotIssuedAssetIds = t.first
            val unregisteredAssetIds = t.second
            val archives = t.third

            val registerAssetStreams = unregisteredAssetIds.map { assetId ->
                val registerAsset = fun(aId: String): Single<String> {
                    val archive = archives.find { a -> a.assetId == aId }!!
                    val params = RegistrationParams(archive.id.toString(), archive.metaData)
                    params.setFingerprintFromData(archive.hashBytes)
                    params.sign(account.authKeyPair)
                    return bitmarkRepo.registerAsset(params).onErrorResumeNext { e ->
                        Single.error(IllegalAccessException("register asset: $aId failed with cause: ${e.message}"))
                    }
                }
                registerAsset(assetId)
            }

            val issueBitmarkStreams = hasNotIssuedAssetIds.map { assetId ->
                val issueBm = fun(aId: String): Single<List<String>> {
                    val params = IssuanceParams(aId, account.toAddress())
                    params.sign(account.authKeyPair)
                    return bitmarkRepo.issueBitmark(params).onErrorResumeNext { e ->
                        Single.error(IllegalAccessException("issue bitmark with asset id: $aId failed with cause: ${e.message}"))
                    }
                }
                issueBm(assetId)
            }

            Single.merge(registerAssetStreams).ignoreElements()
                .andThen(
                    Single.mergeDelayError(issueBitmarkStreams).collectInto(
                        mutableListOf(),
                        BiConsumer<MutableList<List<String>>, List<String>> { collection, data ->
                            collection.add(
                                data
                            )
                        }).map { result -> result.flatten() }
                )
        }
}