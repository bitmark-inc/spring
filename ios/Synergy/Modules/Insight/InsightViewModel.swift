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
    let dateRelay = BehaviorRelay(value: Date().dateAtStartOf(.weekday))
    let timeUnitRelay = BehaviorSubject<TimeUnit>(value: .week)

    // MARK: - Outputs
//    let realmAverageObservable = PublishSubject<Results<Average>>()
//    let realmPostInsightObservable = PublishSubject<Insight>()
//    let realmReactionInsightObservable = PublishSubject<Insight>()
//
//    override init() {
//        super.init()
//
//    }
//
//    func fetchAverage() {
//        timeUnitRelay
//            .flatMap { AverageDataEngine.rx.fetchAndSyncAverage(timeUnit: $0) }
//            .bind(to: realmAverageObservable)
//            .disposed(by: disposeBag)
//    }
//
//    func fetchInsight() {
//        BehaviorRelay.combineLatest(dateRelay, timeUnitRelay)
//            .subscribe(onNext: { [weak self] (date, timeUnit) in
//                guard let self = self else { return }
//
//                var insightScope: InsightScope = (
//                    sectionName: "",
//                    date: date, timeUnit: timeUnit.rawValue)
//
//                // Insight - POSTs
//                insightScope.sectionName = Section.posts.rawValue
//                let postInsightScope = insightScope
//
//                _ = InsightDataEngine.rx.fetchAndSyncInsight(postInsightScope)
//                    .catchError({ (error) -> Single<Insight> in
//                        Global.log.error(error)
//                        return Single.just(Insight())
//                    })
//                    .asObservable()
//                    .bind(to: self.realmPostInsightObservable)
//
//                // Insight - Reactions
//                insightScope.sectionName = Section.reactions.rawValue
//                let reactionInsightScope = insightScope
//
//                _ = InsightDataEngine.rx.fetchAndSyncInsight(reactionInsightScope)
//                    .catchError({ (error) -> Single<Insight> in
//                        Global.log.error(error)
//                        return Single.just(Insight())
//                    })
//                    .asObservable()
//                    .bind(to: self.realmReactionInsightObservable)
//            })
//            .disposed(by: disposeBag)
//    }
}
