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
    let fetchDataResultSubject = PublishSubject<Event<Void>>()
    let realmPostUsageRelay = BehaviorRelay<Usage?>(value: nil)
    let realmReactionUsageRelay = BehaviorRelay<Usage?>(value: nil)

    func fetchUsage() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
            .subscribe(onNext: { [weak self] (date) in
                guard let self = self else { return }
                let timeUnit = self.timeUnitRelay.value

                _ = UsageDataEngine.rx.fetchAndSyncUsage(timeUnit: timeUnit, startDate: date)
                    .catchError({ [weak self] (error) -> Single<[Section: Usage?]> in
                        self?.fetchDataResultSubject.onNext(Event.error(error))
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
