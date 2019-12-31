//
//  LensViewController.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa

class LensViewController: ViewController {

    // MARK: - Properties
    fileprivate lazy var subTitleLabel = makeSubTitleLabel()
    fileprivate lazy var streamDescLabel = makeStreamDescLabel()
    fileprivate lazy var accountButton = makeAccountButton()

    override func bindViewModel() {
        super.bindViewModel()

        accountButton.rx.tap.bind { [weak self] in
            self?.gotoAccountScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let screenTitleLabel = Label()
        screenTitleLabel.applyTitleTheme(
            text: R.string.localizable.lens().localizedUppercase,
            colorTheme: .yukonGold)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(screenTitleLabel).marginTop(OurTheme.dashboardPaddingScreenTitle)
                flex.addItem(subTitleLabel).marginTop(2)

                flex.addItem(streamDescLabel).marginTop(36)

                flex.addItem(accountButton)
                    .width(20).height(20)
                    .position(.absolute).top(21).right(18)
            }
    }
}

// MARK: - Navigator
extension LensViewController {
    fileprivate func gotoAccountScreen() {
        let viewModel = AccountViewModel()
        navigator.show(segue: .account(viewModel: viewModel), sender: self)
    }
}

extension LensViewController {
    fileprivate func makeSubTitleLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.localizable.comingSoon().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(18)),
            colorTheme: .black)
        return label
    }

    fileprivate func makeStreamDescLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: R.string.phrase.lensDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)
        label.numberOfLines = 0
        return label
    }

    fileprivate func makeAccountButton() -> Button {
        let button = SubmitButton()
        button.setImage(R.image.account_icon(), for: .normal)
        return button
    }
}
