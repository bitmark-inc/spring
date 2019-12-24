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

typealias FilterScope1 = (usageScope: UsageScope, filterBy: GroupKey, filterValue: String)

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
            timelineText = buildTimestamp()
        case .friend, .place:
            sectionTitle = R.string.localizable.pluralPost().localizedUppercase
            if let tags = filterScope.filterValue as? [String] {
                let titleTag = tags.count == 1 ? tags.first! : R.string.localizable.graphKeyOther()
                taggedText = R.string.phrase.postSectionTitleTag(titleTag)
            }
            timelineText = buildTimestamp()
        case .day:
            sectionTitle = R.string.localizable.pluralPost().localizedUppercase
            if let selectedDate = filterScope.filterValue as? Date {
                let (startDate, endDate) = selectedDate.extractSubPeriod(timeUnit: filterScope.timeUnit)
                timelineText = buildTimestamp(startDate: startDate, endDate: endDate)
            } else {
                timelineText = ""
            }
        }

        return (sectionTitle: sectionTitle, taggedText: taggedText, timelineText: timelineText)
    }

    func buildTimestamp() -> String {
        let date = filterScope.date; let timeUnit = filterScope.timeUnit
        let (startDate, endDate) = date.extractDatePeriod(timeUnit: timeUnit)

        return buildTimestamp(startDate: startDate, endDate: endDate)
    }

    func buildTimestamp(startDate: Date, endDate: Date) -> String {
        return startDate.year == endDate.year ?
            startDate.toFormat(Constant.TimeFormat.full) + "-" + endDate.toFormat(Constant.TimeFormat.short) :
            startDate.toFormat(Constant.TimeFormat.full) + " - " + endDate.toFormat(Constant.TimeFormat.full)
    }
}
