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

    static func updateMetadata(for fbmAccount: FbmAccount) -> Completable {
        Completable.deferred {
            var metadataValue: Metadata!
            do {
                metadataValue = try Converter<Metadata>(from: fbmAccount.metadata).value
            } catch {
                return Completable.error(error)
            }

            // skip when already set metadata for FB Identifier
            guard metadataValue.fbIdentifier == nil
                else {
                    return Completable.empty()
            }

            return Completable.create { (event) -> Disposable in
                _ = KeychainStore.getFBUsername()
                    .map { (username) in
                        return ["fb-identifier": username.sha3()]
                    }
                    .flatMap { FbmAccountService.updateMe(metadata: $0) }
                    .flatMapCompletable { Storage.store($0) }
                    .subscribe(onCompleted: {
                        event(.completed)
                    }, onError: { (error) in
                        event(.error(error))
                    })

                return Disposables.create()
            }

        }
    }
}
