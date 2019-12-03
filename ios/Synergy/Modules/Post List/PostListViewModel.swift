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

    func getPosts() {
        PostDataEngine.rx.fetch(with: filterScope)
            .asObservable()
            .bind(to: postsObservable)
            .disposed(by: disposeBag)
    }
}
