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

    static func fetchAndSyncUsage(_ usageScope: UsageScope) -> Single<Usage> {
        Global.log.info("[start] UsageDataEngine.rx.fetchAndSyncUsage")

        return Single<Usage>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                let usageID = Usage.makeID(usageScope)

                if let usage = realm.object(ofType: Usage.self, forPrimaryKey: usageID) {
                    event(.success(usage))

                    _ = UsageService.get(usageScope)
                        .flatMapCompletable { Storage.store($0) }
                        .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .subscribe(onError: { (error) in
                            guard !AppError.errorByNetworkConnection(error) else { return }
                            Global.log.error(error)
                        })

                } else {
                    _ = UsageService.get(usageScope)
                        .flatMapCompletable { Storage.store($0) }
                        .observeOn(MainScheduler.instance)
                        .subscribe(onCompleted: {

                            guard let usage = realm.object(ofType: Usage.self, forPrimaryKey: usageID) else { return }

                            event(.success(usage))
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
