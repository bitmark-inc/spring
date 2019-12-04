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

class UsageViewController: TabPageViewController {
    
    private let filterSegment = FilterSegment(elements: ["WEEK".localized(),
                                                          "YEAR".localized(),
                                                          "DECADE".localized()
    ])
    
    private let previousPeriodButton: Button = {
        let btn = Button()
        btn.setImage(R.image.previous_period()!, for: .normal)
        return btn
    }()
    
    private let nextPeriodButton: Button = {
        let btn = Button()
        btn.setImage(R.image.next_period()!, for: .normal)
        return btn
    }()
    
    private lazy var periodNameLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 18))
    private lazy var periodDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
    private lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextRegular(size: 18))
    
    private lazy var collectionView: UsageCollectionView = {
        let v = UsageCollectionView()
        v.postListNavigateHandler = { filterScope in
            (self.viewModel as? UsageViewModel)?.goToPostListScreen(filterScope: filterScope)
        }
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setThemedScreenTitle(text: R.string.localizable.usagE())
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        // Fake data
        periodNameLabel.text = "THIS DECADE"
        periodDescriptionLabel.text = "2010-2019"
        periodNameLabel.textAlignment = .center
        periodDescriptionLabel.textAlignment = .center
        subTitleLabel.text = R.string.localizable.howyouusefacebooK()

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
        
        let d = filterSegment.rx.selectedIndex.share(replay: 1, scope: .forever)
        d.map { (index) -> TimeUnit in
            switch index {
            case 0:
                return .week
            case 1:
                return .year
            case 2:
                return .decade
            default:
                return .week
            }
            }.bind(to: collectionView.rx.timeUnit)
            .disposed(by: disposeBag)
        
        d.bind(to: periodNameLabel.rx.text)
        .disposed(by: disposeBag)
        
        d.map { (index) -> String in
            switch index {
            case 0:
                return "Dec 1st - Dec 7th"
            case 1:
                return "Jan 1st - Dec 31st"
            case 2:
                return "2010 - 2019"
            default:
                return ""
            }
        }.bind(to: periodDescriptionLabel.rx.text)
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
        
        let periodBrowseContentView = UIView()
        periodBrowseContentView.flex.direction(.row).define { (flex) in
            flex.justifyContent(.center)
            flex.alignItems(.stretch)
            flex.addItem(previousPeriodButton)
            flex.addItem(periodNameLabel).grow(1)
            flex.addItem(nextPeriodButton)
        }
        
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(subTitleLabel).marginTop(2).marginLeft(18).marginRight(18)
            flex.addItem(filterSegment).marginTop(36).marginLeft(18).marginRight(18).height(40)
            flex.addItem(periodBrowseContentView).marginTop(18).marginLeft(18).marginRight(18).height(19)
            flex.addItem(periodDescriptionLabel).marginTop(6).height(10).alignSelf(.stretch)
            flex.addItem(collectionView).marginTop(10).marginBottom(0).grow(1)
        }
        
    }
}
