//
//  InsightViewController.swift
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

class InsightViewController: TabPageViewController {
    
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
    
    private lazy var collectionView: InsightCollectionView = {
        let v = InsightCollectionView()
        v.postListNavigateHandler = { filterScope in
            loadingState.onNext(.loading)
            (self.viewModel as? InsightViewModel)?.goToPostListScreen(filterScope: filterScope)
        }
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setThemedScreenTitle(text: R.string.localizable.insightS())
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        // Fake data
        periodNameLabel.text = "THIS DECADE"
        periodDescriptionLabel.text = "2010-2019"
        subTitleLabel.text = R.string.localizable.howfacebookusesyoU()

//        guard let viewModel = viewModel as? InsightViewModel else { return }
//
//        viewModel.realmPostInsightObservable
//            .subscribe(onNext: { [weak self] (realmInsight) in
//                guard let self = self else { return }
//                self.bindPostInsightData(realmInsight)
//
//            }, onError: { (error) in
//                Global.log.error(error)
//            })
//            .disposed(by: disposeBag)
//
//        viewModel.realmReactionInsightObservable
//            .subscribe(onNext: { [weak self] (realmInsight) in
//                guard let self = self else { return }
//                self.bindReactionInsightData(realmInsight)
//            }, onError: { (error) in
//                Global.log.error(error)
//            })
//            .disposed(by: disposeBag)
        
        filterSegment.rx.selectedIndex.map { (index) -> TimeUnit in
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

//        viewModel.fetchInsight()
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
        
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(subTitleLabel).marginTop(2).marginLeft(18).marginRight(18)
            flex.addItem(filterSegment).marginTop(36).marginLeft(18).marginRight(18).height(40)
            flex.addItem(periodBrowseContentView).marginTop(18).marginLeft(18).marginRight(18).height(19)
            flex.addItem(periodDescriptionLabel).marginTop(9).height(10).alignSelf(.center)
            flex.addItem(collectionView).marginTop(10).marginBottom(0).grow(1)
        }
    }
}
