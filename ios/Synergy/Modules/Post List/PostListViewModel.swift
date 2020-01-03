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

class PostListViewModel: ViewModel {

    // MARK: - Inputs
    let filterScope: FilterScope!

    // MARK: - Outputs
    let postsRelay = BehaviorRelay<Results<Post>?>(value: nil)

    // MARK: - Init
    init(filterScope: FilterScope) {
        self.filterScope = filterScope
        super.init()
    }

    deinit {
        // cancel syncing posts
        PostDataEngine.datePeriodSubject?.onCompleted()
    }

    func getPosts() {
        PostDataEngine.rx.fetch(with: filterScope)
            .map { $0.sorted(byKeyPath: "timestamp", ascending: false)}
            .asObservable()
            .bind(to: postsRelay)
            .disposed(by: disposeBag)
    }

    func loadMore() {
        guard let posts = postsRelay.value else { return }
        let currentNumberOfPosts = posts.count

        PostDataEngine.triggerSubject?
            .filter({ $0 == .remoteLoaded}).take(1)
            .asSingle()
            .subscribe(onSuccess: { (_) in
                let updatedNumberOfPosts = posts.count

                if updatedNumberOfPosts <= currentNumberOfPosts {
                    self.loadMore()
                }
            })
            .disposed(by: disposeBag)

        PostDataEngine.triggerSubject?.onNext(.triggerRemoteLoad)
    }

    func makeSectionTitle() -> String {
        switch filterScope.filterBy {
        case .type:
            return "plural.\(filterScope.filterValue)".localized().localizedUppercase
        default:
            return R.string.localizable.pluralPost().localizedUppercase
        }
    }

    func makeTaggedText() -> String? {
        switch filterScope.filterBy {
        case .friend, .place:
            var titleTag = ""
            if let tags = filterScope.filterValue as? [String] {
                titleTag = tags.count == 1 ? tags.first! : R.string.localizable.graphKeyOther()
            } else if let tag = filterScope.filterValue as? String {
                titleTag = tag
            }
            return R.string.phrase.postSectionTitleTag(titleTag)
        default:
            return nil
        }
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
