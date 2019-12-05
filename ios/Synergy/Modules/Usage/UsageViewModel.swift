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
    let dateRelay = BehaviorRelay(value: Date().dateAtStartOf(.weekday))
    let timeUnitRelay = BehaviorSubject<TimeUnit>(value: .week)

    // MARK: - Outputs
    let realmAverageObservable = PublishSubject<Results<Average>>()
    let realmPostUsageObservable = PublishSubject<Usage>()
    let realmReactionUsageObservable = PublishSubject<Usage>()

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
        BehaviorRelay.combineLatest(dateRelay, timeUnitRelay)
            .subscribe(onNext: { [weak self] (date, timeUnit) in
                guard let self = self else { return }

                var usageScope: UsageScope = (
                    sectionName: "",
                    date: date, timeUnit: timeUnit.rawValue)

                // Usage - POSTs
                usageScope.sectionName = Section.posts.rawValue
                let postUsageScope = usageScope

                _ = UsageDataEngine.rx.fetchAndSyncUsage(postUsageScope)
                    .catchError({ (error) -> Single<Usage> in
                        Global.log.error(error)
                        return Single.just(Usage())
                    })
                    .asObservable()
                    .bind(to: self.realmPostUsageObservable)

                // Usage - Reactions
                usageScope.sectionName = Section.reactions.rawValue
                let reactionUsageScope = usageScope

                _ = UsageDataEngine.rx.fetchAndSyncUsage(reactionUsageScope)
                    .catchError({ (error) -> Single<Usage> in
                        Global.log.error(error)
                        return Single.just(Usage())
                    })
                    .asObservable()
                    .bind(to: self.realmReactionUsageObservable)
            })
            .disposed(by: disposeBag)
    }
    
    func goToPostListScreen(filterScope: FilterScope) {
        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel))
    }
}
