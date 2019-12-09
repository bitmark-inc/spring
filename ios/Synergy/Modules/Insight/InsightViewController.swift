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

class InsightViewController: ViewController {
    private lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextRegular(size: 18))
    
    private lazy var tableView: InsightTableView = {
        let v = InsightTableView()
        v.postListNavigateHandler = { filterScope in
            loadingState.onNext(.loading)
            (self.viewModel as? InsightViewModel)?.goToPostListScreen(filterScope: filterScope)
        }
        return v
    }()

    override func setupViews() {
        super.setupViews()

        let screenTitleLabel = Label()
        screenTitleLabel.applyTitleTheme(
            text: R.string.localizable.insights().localizedUppercase,
            colorTheme: .internationalKleinBlue)

        subTitleLabel.text = R.string.localizable.howfacebookusesyoU()

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
