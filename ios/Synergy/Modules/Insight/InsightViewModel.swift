//
//  InsightViewModel.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift
import SwiftDate

class InsightViewModel: ViewModel {

    // MARK: - Inputs
    let dateRelay = BehaviorRelay(value: Date().in(Locales.english).dateAtStartOf(.weekOfMonth).date)
    let timeUnitRelay = BehaviorRelay<TimeUnit>(value: .week)

    // MARK: - Outputs
    let fetchDataResultSubject = PublishSubject<Event<Void>>()
    let realmIncomeInsightRelay = BehaviorRelay<Insight?>(value: nil)
    let realmMoodInsightRelay = BehaviorRelay<Insight?>(value: nil)

    func fetchInsight() {
        dateRelay // ignore timeUnit change, cause when timeUnit change, it trigger date change also
        .subscribe(onNext: { [weak self] (date) in
            guard let self = self else { return }
            let timeUnit = self.timeUnitRelay.value

            _ = InsightDataEngine.rx.fetchAndSyncInsight(timeUnit: timeUnit, startDate: date)
                .catchError({ [weak self] (error) -> Single<[Section: Insight?]> in
                    self?.fetchDataResultSubject.onNext(Event.error(error))
                    return Single.just([:])
                })
                .asObservable()
                .subscribe(onNext: { [weak self] (insights) in
                    guard let self = self else { return }
                    self.realmIncomeInsightRelay.accept(insights[.fbIncome] ?? nil)
                    self.realmMoodInsightRelay.accept(insights[.mood] ?? nil)
                })
        })
        .disposed(by: disposeBag)

    }
}
