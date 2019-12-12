//
//  PostListViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm
import SwiftDate

typealias FilterScope = (usageScope: UsageScope, filterBy: GroupKey, filterValue: String)

class PostListViewModel: ViewModel {

    // MARK: - Inputs
    let filterScope: FilterScope!

    // MARK: - Outputs
    let postsObservable = PublishSubject<Results<Post>>()

    // MARK: - Init
    init(filterScope: FilterScope) {
        self.filterScope = filterScope
        super.init()
    }

    var screenTitleFromFilter: String {
        switch filterScope.filterBy {
        case .type:
            return "plural.\(filterScope.filterValue)".localized().localizedUppercase
        default:
            return R.string.localizable.pluralPost().localizedUppercase
        }
    }

    func getPosts() {
        PostDataEngine.rx.fetch(with: filterScope)
            .map { $0.sorted(byKeyPath: "timestamp", ascending: false)}
            .asObservable()
            .bind(to: postsObservable)
            .disposed(by: disposeBag)
    }

    func generateSectionInfoText() -> (sectionTitle: String, taggedText: String, timelineText: String) {
        let sectionTitle: String!
        var taggedText: String = ""
        let timelineText: String!
        switch filterScope.filterBy {
        case .type:
            sectionTitle = "plural.\(filterScope.filterValue)".localized().localizedUppercase
            timelineText = buidlTimestamp()
        case .friend, .place:
            sectionTitle = R.string.localizable.pluralPost().localizedUppercase
            taggedText = R.string.phrase.postSectionTitleTag(filterScope.filterValue)
            timelineText = buidlTimestamp()
        case .day:
            sectionTitle = R.string.localizable.pluralPost().localizedUppercase
            timelineText = Date().toFormat(Constant.TimeFormat.full) // TODO not filter by day now
        }

        return (sectionTitle: sectionTitle, taggedText: taggedText, timelineText: timelineText)
    }

    func buidlTimestamp() -> String {
        let date = filterScope.usageScope.date
        guard let periodUnit = TimeUnit(rawValue: filterScope.usageScope.timeUnit) else { return "" }

        let startDate: Date!
        let endDate: Date!

        switch periodUnit {
        case .week:
            startDate = date.dateAtStartOf(.weekOfMonth)
            endDate = date.dateAtEndOf(.weekOfMonth)
        case .year:
            startDate = date.dateAtStartOf(.year)
            endDate = date.dateAtEndOf(.year) - 12.hours // TODO:
        case .decade:
            startDate = (date - 10.years).dateAtStartOf(.year)
            endDate = Date() // TODO:
        }

        return startDate.year == endDate.year ?
            startDate.toFormat(Constant.TimeFormat.full) + "-" + endDate.toFormat(Constant.TimeFormat.short) :
            startDate.toFormat(Constant.TimeFormat.full) + " - " + endDate.toFormat(Constant.TimeFormat.full)
    }
}
