//
//  AverageDataEngine+Rx.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class AverageDataEngine {}

extension AverageDataEngine: ReactiveCompatible {}

extension Reactive where Base: AverageDataEngine {

    static func fetchAndSyncAverage(timeUnit: TimeUnit) -> Single<Results<Average>> {
        Global.log.info("[start] AverageDataEngine.rx.fetchAndSyncAverage")

        return Single<Results<Average>>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()
                let averages = realm.objects(Average.self).filter("timeUnit == %@", timeUnit.rawValue)
                event(.success(averages))

                _ = UsageService.getAverage(timeUnit: timeUnit)
                    .flatMapCompletable { Storage.store($0) }
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onError: { (error) in
                        guard !AppError.errorByNetworkConnection(error) else { return }
                        Global.log.error(error)
                    })
            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }
}
