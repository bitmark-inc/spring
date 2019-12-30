//
//  UsageViewModel.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift
import SwiftDate

class UsageViewModel: ViewModel {

    // MARK: - Inputs
    let dateRelay = BehaviorRelay(value: Date().in(Locales.english).dateAtStartOf(.weekOfMonth).date)
    let timeUnitRelay = BehaviorRelay<TimeUnit>(value: .week)

    // MARK: - Outputs
    let realmAverageObservable = PublishSubject<Results<Average>>()
    let realmPostUsageRelay = BehaviorRelay<Usage?>(value: nil)
    let realmReactionUsageRelay = BehaviorRelay<Usage?>(value: nil)

    override init() {
        super.init()
    }

    func fetchAverage() {
        timeUnitRelay
            .flatMap { AverageDataEngine.rx.fetchAndSyncAverage(timeUnit: $0) }
            .bind(to: realmAverageObservable)
            .disposed(by: disposeBag)
    }

    func fetchUsage() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
            .subscribe(onNext: { [weak self] (date) in
                guard let self = self else { return }
                let timeUnit = self.timeUnitRelay.value

                _ = UsageDataEngine.rx.fetchAndSyncUsage(timeUnit: timeUnit, startDate: date)
                    .catchError({ (error) -> Single<[Section: Usage?]> in
                        Global.log.error(error)
                        return Single.just([:])
                    })
                    .asObservable()
                    .subscribe(onNext: { [weak self] (usages) in
                        guard let self = self else { return }
                        self.realmPostUsageRelay.accept(usages[.post] ?? nil)
                        self.realmReactionUsageRelay.accept(usages[.reaction] ?? nil)
                    })
            })
            .disposed(by: disposeBag)
    }
}
