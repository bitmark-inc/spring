//
//  ViewRecoveryKeyWarningViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class ViewRecoveryKeyWarningViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var writeDownRecoveryKeyButton = makeContinueButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        writeDownRecoveryKeyButton.rx.tap.bind { [weak self] in
            guard let self = self,
                let userDefault = Global.current.userDefault
                else {
                    return
            }

            if userDefault.isAccountSecured {
                _ = BiometricAuth.authorizeAccess()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onCompleted: { [weak self] in
                        self?.gotoViewRecoveryKeyScreen()
                    })
            } else {
                self.gotoViewRecoveryKeyScreen()
            }
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()
        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.accountRecoveryKeyWarningDescription(),
            font: R.font.atlasGroteskThin(size: Size.ds(22)),
            colorTheme: .tundora, lineHeight: 1.32)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                flex.addItem(descriptionLabel)

                flex.addItem(writeDownRecoveryKeyButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

extension ViewRecoveryKeyWarningViewController {
    fileprivate func gotoViewRecoveryKeyScreen() {
        let viewModel = ViewRecoveryKeyViewModel()
        navigator.show(segue: .viewRecoverykey(viewModel: viewModel), sender: self)
    }
}

extension ViewRecoveryKeyWarningViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountRecoveryKeyWarningTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.phrase.accountRecoveryKeyWarningWriteDownAction().localizedUppercase)
        submitButton.applyTheme(colorTheme: .mercury)
        return submitButton
    }
}
