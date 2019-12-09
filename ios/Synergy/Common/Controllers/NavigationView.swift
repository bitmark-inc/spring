//
//  NavigationView.swift
//  Synergy
//
//  Created by thuyentruong on 11/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

protocol BackNavigator {
    func makeBlackBackItem() -> Button
    func makeLightBackItem() -> Button
}

extension BackNavigator where Self: ViewController {
    func makeBlackBackItem() -> Button {
        let backButton = Button()
        backButton.applyBlack(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)))
        backButton.contentHorizontalAlignment = .left

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)

        return backButton
    }

    func makeLightBackItem() -> Button {
        let backButton = Button()
        backButton.applyLight(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14)))
        backButton.contentHorizontalAlignment = .left

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)

        return backButton
    }

    func tapToBack() {
        Navigator.default.pop()
    }
}
