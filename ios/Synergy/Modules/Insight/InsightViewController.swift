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
    private lazy var tableView: InsightTableView = {
        let v = InsightTableView()
        v.accountNavigationHandler = { [weak self] in
            self?.gotoAccountScreen()
        }
        return v
    }()

    override func setupViews() {
        super.setupViews()

        let screenTitleLabel = Label()
        screenTitleLabel.applyTitleTheme(
            text: R.string.localizable.insights().localizedUppercase,
            colorTheme: .internationalKleinBlue)

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(tableView).marginBottom(10).grow(1)
            }
    }
}

// MARK: - Navigator
extension InsightViewController {
    fileprivate func goToPostListScreen(filterScope: FilterScope) {
        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    fileprivate func gotoAccountScreen() {
        let viewModel = AccountViewModel()
        navigator.show(segue: .account(viewModel: viewModel), sender: self)
    }
}
