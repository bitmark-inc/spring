//
//  FbmAccountDataEngine.swift
//  Synergy
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class FbmAccountDataEngine {}

extension FbmAccountDataEngine: ReactiveCompatible {}

extension Reactive where Base: FbmAccountDataEngine {

    static func fetchCurrentFbmAccount() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountDataEngine.rx.fetchCurrentFbmAccount")

        return Single<FbmAccount>.create { (event) -> Disposable in
            guard let number = Global.current.account?.getAccountNumber() else {
                return Disposables.create()
            }

            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }
                    
                    let realm = try RealmConfig.currentRealm()
                    if let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number) {
                        event(.success(fbmAccount))
                    } else {
                        _ = FbmAccountService.getMe()
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                guard let fbmAccount = realm.object(ofType: FbmAccount.self, forPrimaryKey: number)
                                    else {
                                        Global.log.error(AppError.incorrectEmptyRealmObject)
                                        return
                                }
                                
                                event(.success(fbmAccount))
                            }, onError: { (error) in
                                event(.error(error))
                            })
                    }
                } catch {
                    event(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    static func updateMetadata(for fbmAccount: FbmAccount, username: String? = nil) -> Completable {
        Completable.deferred {
            var metadataValue: Metadata!
            do {
                metadataValue = try MetadataConverter(from: fbmAccount.metadata).value
            } catch {
                return Completable.error(error)
            }

            // skip when already set metadata for FB Identifier
            guard metadataValue.fbIdentifier == nil
                else {
                    return Completable.empty()
            }

            let fbUsernameSingle = Single<String>.deferred {
                if let username = username {
                    return Single.just(username)
                } else {
                    return KeychainStore.getFBUsername()
                }
            }

            return Completable.create { (event) -> Disposable in
                _ = fbUsernameSingle
                    .map { (username) -> [String: Any] in
                        metadataValue.fbIdentifier = username.sha3()
                        return [
                            "fb-identifier": metadataValue.fbIdentifier!
                        ]
                    }
                    .flatMapCompletable { FbmAccountService.updateMe(metadata: $0) }
                    .subscribe(onCompleted: {
                        autoreleasepool {
                            do {
                                guard let updatedMetadata = try MetadataConverter(from: metadataValue).valueAsString else { return }
                                let realm = try RealmConfig.currentRealm()
                                try realm.write {
                                    fbmAccount.metadata = updatedMetadata
                                }
                                event(.completed)
                            } catch {
                                event(.error(error))
                            }
                        }
                    }, onError: { (error) in
                        event(.error(error))
                    })

                return Disposables.create()
            }

        }
    }
}
