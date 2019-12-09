//
//  UsageViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import BitmarkSDK
import RxSwift
import RxCocoa
import RxRealm
import FlexLayout
import RealmSwift
import Realm

class UsageViewController: ViewController {
    
    private lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextRegular(size: 18))
    
    private lazy var tableView: UsageTableView = {
        let v = UsageTableView()
        v.postListNavigateHandler = { filterScope in
            (self.viewModel as? UsageViewModel)?.goToPostListScreen(filterScope: filterScope)
        }
        return v
    }()
    
    override func bindViewModel() {
        super.bindViewModel()
        
        guard let viewModel = viewModel as? UsageViewModel else { return }

        viewModel.realmPostUsageObservable
            .subscribe(onNext: { [weak self] (realmUsage) in
                guard let self = self else { return }
                self.bindPostUsageData(realmUsage)

            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)

        viewModel.realmReactionUsageObservable
            .subscribe(onNext: { [weak self] (realmUsage) in
                guard let self = self else { return }
                self.bindReactionUsageData(realmUsage)
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
        
//        filterSegment.selectedIndex = 0
//        viewModel.fetchUsage()
    }

    fileprivate func bindPostUsageData(_ realmUsage: Usage) {
        let realmUsageOb = Observable.from(object: realmUsage)

        let realmGroupsUsageOb = realmUsageOb.map { $0.groups }.share(replay: 1)

        // Group by .type
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.type.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (postUsageGroupByType) in
                // TODO: Fill Data in postUsageGroupByType

            })
            .disposed(by: disposeBag)

        // Group by .day
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.day.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (postUsageGroupByDay) in
                // TODO: Fill Data in postUsageGroupByDay

            })
            .disposed(by: disposeBag)

        // Group by .friend
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.friend.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (postUsageGroupByFriend) in
                // TODO: Fill Data in postUsageGroupByFriend

            })
            .disposed(by: disposeBag)

        // Group by .place
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.place.rawValue }) }.filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (postUsageGroupByPlace) in
                // TODO: Fill Data in postUsageGroupByPlace

            })
            .disposed(by: disposeBag)

    }

    fileprivate func bindReactionUsageData(_ realmUsage: Usage) {
        let realmUsageOb = Observable.from(object: realmUsage)

        let realmGroupsUsageOb = realmUsageOb.map { $0.groups }.share(replay: 1)

        // Group by .type
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.type.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (reactionUsageGroupByType) in
                // TODO: Fill Data in reactionUsageGroupByType

            })
            .disposed(by: disposeBag)

        // Group by .day
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.day.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (reactionUsageGroupByDay) in
                // TODO: Fill Data in reactionUsageGroupByDay

            })
            .disposed(by: disposeBag)

        // Group by .friend
        realmGroupsUsageOb
            .map { $0.first(where: { $0.key == GroupKey.friend.rawValue }) }
            .filterNil()
            .map { try Graphs(from: $0.graphs).value }.filterNil()
            .subscribe(onNext: { [weak self] (reactionUsageGroupByFriend) in
                // TODO: Fill Data in reactionUsageGroupByFriend

            })
            .disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let screenTitleLabel = Label()
        screenTitleLabel.applyTitleTheme(
            text: R.string.localizable.usage().localizedUppercase,
            colorTheme: .cognac)

        subTitleLabel.setText(R.string.localizable.howyouusefacebooK())

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem().padding(OurTheme.paddingInset)
                    .direction(.column).define { (flex) in
                        flex.addItem(screenTitleLabel).marginTop(OurTheme.dashboardPaddingScreenTitle)
                        flex.addItem(subTitleLabel).marginTop(2)
                }

                flex.addItem(tableView).marginBottom(10).grow(1)
            }
    }
}
