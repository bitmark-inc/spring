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
    private lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextRegular(size: 18))
    
    private lazy var tableView: InsightTableView = {
        let v = InsightTableView()
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
        
        subTitleLabel.text = R.string.localizable.howfacebookusesyoU()
    }

    override func setupViews() {
        super.setupViews()
        
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(subTitleLabel).marginTop(2).marginLeft(18).marginRight(18)
            flex.addItem(tableView).marginBottom(10).grow(1)
        }
    }
}
