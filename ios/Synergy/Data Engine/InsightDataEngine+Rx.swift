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
}

extension InsightDataEngine: ReactiveCompatible {}

extension Reactive where Base: InsightDataEngine {

    static func fetchAndSyncInsight(timeUnit: TimeUnit, startDate: Date) -> Single<[Section: Insight?]> {
        Global.log.info("[start] InsightDataEngine.rx.fetchAndSyncInsight")

        return Single<[Section: Insight?]>.create { (event) -> Disposable in
            autoreleasepool {
                do {
                    guard Thread.current.isMainThread else {
                        throw AppError.incorrectThread
                    }

                    let realm = try RealmConfig.currentRealm()

                    let fbIncomeInsightID = SectionScope(date: startDate, timeUnit: timeUnit, section: .fbIncome).makeID()
                    let moodInsightID = SectionScope(date: startDate, timeUnit: timeUnit, section: .mood).makeID()

                    let fbIncomeInsight = realm.object(ofType: Insight.self, forPrimaryKey: fbIncomeInsightID)
                    let moodInsight = realm.object(ofType: Insight.self, forPrimaryKey: moodInsightID)

                    if fbIncomeInsight != nil || moodInsight != nil {
                        event(.success([
                            .fbIncome: fbIncomeInsight,
                            .mood: moodInsight
                        ]))

                        _ = InsightService.get(in: timeUnit, startDate: startDate)
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                            .subscribe(onError: { (error) in
                                Global.backgroundErrorSubject.onNext(error)
                            })
                    } else {
                        _ = InsightService.get(in: timeUnit, startDate: startDate)
                            .flatMapCompletable { Storage.store($0) }
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                let fbIncomeInsight = realm.object(ofType: Insight.self, forPrimaryKey: fbIncomeInsightID)
                                let moodInsight = realm.object(ofType: Insight.self, forPrimaryKey: moodInsightID)

                                event(.success([
                                    .fbIncome: fbIncomeInsight,
                                    .mood: moodInsight
                                ]))
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
