//
//  UsageDataEngine+Rx.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class UsageDataEngine {}

extension UsageDataEngine: ReactiveCompatible {}

extension Reactive where Base: UsageDataEngine {

    static func fetchAndSyncUsage(timeUnit: TimeUnit, startDate: Date) -> Single<[Section: Usage?]> {
        Global.log.info("[start] UsageDataEngine.rx.fetchAndSyncUsage")

        return Single<[Section: Usage?]>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()

                let postUsageID = SectionScope(date: startDate, timeUnit: timeUnit, section: .post).makeID()
                let reactionUsageID = SectionScope(date: startDate, timeUnit: timeUnit, section: .reaction).makeID()

                if let postUsage = realm.object(ofType: Usage.self, forPrimaryKey: postUsageID),
                   let reactionUsage = realm.object(ofType: Usage.self, forPrimaryKey: reactionUsageID) {

                    event(.success([
                        .post: postUsage,
                        .reaction: reactionUsage
                    ]))

                    _ = UsageService.get(in: timeUnit, startDate: startDate)
                        .flatMapCompletable { Storage.store($0) }
                        .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .subscribe(onError: { (error) in
                            Global.backgroundErrorSubject.onNext(error)
                        })

                } else {
                    _ = UsageService.get(in: timeUnit, startDate: startDate)
                        .flatMapCompletable { Storage.store($0) }
                        .observeOn(MainScheduler.instance)
                        .subscribe(onCompleted: {
                            let postUsage = realm.object(ofType: Usage.self, forPrimaryKey: postUsageID)
                            let reactionUsage = realm.object(ofType: Usage.self, forPrimaryKey: reactionUsageID)

                            event(.success([
                                .post: postUsage,
                                .reaction: reactionUsage
                            ]))
                        }, onError: { (error) in
                            event(.error(error))
                        })
                }
            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }
}
