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
    
    private lazy var periodNameLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 18))
    private lazy var periodDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))
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
        
        setThemedScreenTitle(text: R.string.localizable.insightS(), color: UIColor(hexString: "#0011AF"))
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        // Fake data
        periodNameLabel.text = "THIS WEEK"
        periodDescriptionLabel.text = "2019 Dec 1st - Dec 7th"
        periodNameLabel.textAlignment = .center
        periodDescriptionLabel.textAlignment = .center
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
        
        d.map { (index) -> String in
            switch index {
            case 0:
                return "THIS WEEK"
            case 1:
                return "THIS YEAR"
            case 2:
                return "THIS DECADE"
            default:
                return ""
            }
        }.bind(to: periodNameLabel.rx.text)
        .disposed(by: disposeBag)
        
        d.map { (index) -> String in
            switch index {
            case 0:
                return "2019 Dec 1st - Dec 7th"
            case 1:
                return "2019 Jan 1st - Dec 31st"
            case 2:
                return "2010 - 2019"
            default:
                return ""
            }
        }.bind(to: periodDescriptionLabel.rx.text)
        .disposed(by: disposeBag)

//        viewModel.fetchInsight()
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
            flex.alignItems(.stretch)
            flex.addItem(subTitleLabel).marginTop(2).marginLeft(18).marginRight(18)
            flex.addItem(filterSegment).marginTop(18).marginLeft(18).marginRight(18).height(40)
            flex.addItem(periodBrowseContentView).marginTop(18).marginLeft(18).marginRight(18).height(19)
            flex.addItem(periodDescriptionLabel).marginTop(9).height(10).alignSelf(.stretch)
            flex.addItem(collectionView).marginTop(10).marginBottom(0).grow(1)
        }
    }
}
