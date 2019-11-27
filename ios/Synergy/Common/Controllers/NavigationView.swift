//
//  NavigationView.swift
//  Synergy
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

protocol BackNavigator {
    func showBlackBackItem()
    func showLightBackItem()
}

extension BackNavigator where Self: ViewController {

    func showBlackBackItem() {
        let backButton = Button()
        backButton.applyBlack(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)))

        addIntoNavigationView(backButton: backButton)
    }

    func showLightBackItem() {
        let backButton = Button()
        backButton.applyLight(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)))

        addIntoNavigationView(backButton: backButton)
    }

    func tapToBack() {
        Navigator.default.pop()
    }

    fileprivate func addIntoNavigationView(backButton: Button) {
        navigationViewHeightConstraint.update(offset: navigationViewHeight)
        navigationView.addSubview(backButton)

        backButton.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview()
        }

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)
    }
}
