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
    
    private lazy var postDataBadgeView: UsageDataBadgeView = {
        let u = UsageDataBadgeView()
        u.updownImageView.image = R.image.usage_up()
        u.percentageLabel.text = "5%"
        u.descriptionLabel.text = "POSTS".localized()
        return u
    }()
    
    private lazy var reactionsDataBadgeView: UsageDataBadgeView = {
        let u = UsageDataBadgeView()
        u.updownImageView.image = R.image.usage_down()
        u.percentageLabel.text = "18%"
        u.descriptionLabel.text = "REACTIONS".localized()
        return u
    }()
    
    private lazy var messagesDataBadgeView: UsageDataBadgeView = {
        let u = UsageDataBadgeView()
        u.updownImageView.image = R.image.usage_up()
        u.percentageLabel.text = "22%"
        u.descriptionLabel.text = "MESSAGES".localized()
        return u
    }()
    
    private lazy var collectionView = UsageCollectionView()

    override func bindViewModel() {
        super.bindViewModel()
        
        // Fake data
        periodNameLabel.text = "THIS DECADE"
        periodDescriptionLabel.text = "2010-2019"

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

        viewModel.fetchUsage()
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
            flex.justifyContent(.spaceBetween)
            flex.alignItems(.stretch)
            flex.addItem(previousPeriodButton).alignContent(.start)
            flex.addItem(periodNameLabel).alignContent(.center)
            flex.addItem(nextPeriodButton).alignContent(.end)
        }
        
        let usageDataBadgeContentView = UIView()
        usageDataBadgeContentView.flex.direction(.row).define { (flex) in
            flex.alignItems(.stretch)
            flex.addItem(postDataBadgeView).width(33.33%)
            flex.addItem(reactionsDataBadgeView).width(33.33%)
            flex.addItem(messagesDataBadgeView).width(33.33%)
        }
        
        contentView.flex.direction(.column).define { (flex) in
            flex.alignItems(.stretch)
            flex.addItem(filterSegment).marginTop(Size.dh(27)).height(40)
            flex.addItem(periodBrowseContentView).marginTop(18).height(19)
            flex.addItem(periodDescriptionLabel).marginTop(6).height(10).alignSelf(.center)
            flex.addItem(usageDataBadgeContentView).marginTop(25).height(34)
            flex.addItem(collectionView).marginTop(10).marginBottom(0).height(100%)
        }
    }
}

class UsageDataBadgeView: UIView {
    private let disposeBag = DisposeBag()
    
    let updownImageView = UIImageView()
    let percentageLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 15))
    let descriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let toplineView = UIView()
        toplineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.center)
            flex.addItem(updownImageView)
            flex.addItem(percentageLabel).margin(4)
        }
        
        self.flex.direction(.column).define { (flex) in
            flex.alignItems(.start)
            flex.addItem(toplineView)
            flex.addItem(descriptionLabel).marginTop(6)
        }
        
        themeService.rx
            .bind({ $0.blackTextColor }, to: updownImageView.rx.tintColor)
            .bind({ $0.blackTextColor }, to: percentageLabel.rx.textColor)
            .bind({ $0.blackTextColor }, to: descriptionLabel.rx.textColor)
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
