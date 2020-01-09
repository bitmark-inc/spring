//
//  InsightDataEngine+Rx.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class InsightDataEngine {
    static func fetchAdsCategories() -> Results<UserInfo>? {
        autoreleasepool {
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                return realm.objects(UserInfo.self).filter("key == %@", UserInfoKey.adsCategory.rawValue)
            } catch {
                Global.log.error(error)
                return nil
            }
        }
    }

    static func existsAdsCategories() -> Bool {
        autoreleasepool {
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                return realm.objects(UserInfo.self)
                    .filter("key == %@", UserInfoKey.adsCategory.rawValue)
                    .count > 0
            } catch {
                Global.log.error(error)
                return false
            }
        }
    }
}

extension InsightDataEngine: ReactiveCompatible {}

extension Reactive where Base: InsightDataEngine {

    static func fetchAndSyncInsight() -> Single<UserInfo?> {
        Global.log.info("[start] InsightDataEngine.rx.fetchAndSyncInsight")

        return Single<UserInfo?>.create { (event) -> Disposable in
            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }

                    let realm = try RealmConfig.currentRealm()

                    let insightsInfo = realm.object(ofType: UserInfo.self, forPrimaryKey: Global.userInsightID)

                    if insightsInfo != nil {
                        event(.success(insightsInfo))

                        _ = InsightService.getInUserInfo()
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .subscribe(onError: { (error) in
                                Global.backgroundErrorSubject.onNext(error)
                            })
                    } else {
                        _ = InsightService.getInUserInfo()
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                let insightsInfo = realm.object(ofType: UserInfo.self, forPrimaryKey: Global.userInsightID)
                                event(.success(insightsInfo))
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
}
