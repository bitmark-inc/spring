//
//  ReactionListViewModel.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm
import SwiftDate

class ReactionListViewModel: ViewModel {

    // MARK: - Inputs
    let filterScope: FilterScope!

    // MARK: - Outputs
    let reactionsRelay = BehaviorRelay<Results<Reaction>?>(value: nil)

    // MARK: - Init
    init(filterScope: FilterScope) {
        self.filterScope = filterScope
        super.init()
    }

    deinit {
        // cancel syncing reactions
        ReactionDataEngine.datePeriodSubject?.onCompleted()
    }

    func getReactions() {
        ReactionDataEngine.rx.fetch(with: filterScope)
            .map { $0.sorted(byKeyPath: "timestamp", ascending: false)}
            .asObservable()
            .bind(to: reactionsRelay)
            .disposed(by: disposeBag)
    }

    func loadMore() {
        guard let reactions = reactionsRelay.value else { return }
        let currentNumberOfReactions = reactions.count

        ReactionDataEngine.triggerSubject?
            .filter({ $0 == .remoteLoaded}).take(1)
            .asSingle()
            .subscribe(onSuccess: { (_) in
                let updatedNumberOfReactions = reactions.count

                if updatedNumberOfReactions <= currentNumberOfReactions {
                    self.loadMore()
                }
            })
            .disposed(by: disposeBag)

        ReactionDataEngine.triggerSubject?.onNext(.triggerRemoteLoad)
    }

    func makeSectionTitle() -> String {
        return R.string.localizable.pluralReaction().localizedUppercase
    }

    func makeTaggedText() -> String? {
        return nil
    }

    func makeTimelineText() -> String? {
        let timeUnit = filterScope.timeUnit

        switch filterScope.filterBy {
        case .day:
            guard let selectedDate = filterScope.filterValue as? Date else { return nil }

            let datePeriod = selectedDate.extractSubPeriod(timeUnit: filterScope.timeUnit)
            return datePeriod.makeTimelinePeriodText(in: timeUnit.subDateComponent)
        default:
            let datePeriod = filterScope.date.extractDatePeriod(timeUnit: timeUnit)
            return datePeriod.makeTimelinePeriodText(in: timeUnit)
        }
    }
}
