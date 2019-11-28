//
//  SignInWallViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SwifterSwift
import FlexLayout

class SignInWallViewController: LaunchingViewController {

    // MARK: - Properties
    lazy var getStartedButton = makeGetStartedButton()
    lazy var signInButton = makeSignInButton()

    // MARK: Handlers
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? SignInWallViewModel else { return }

        getStartedButton.rx.tap.bind {
            viewModel.gotoHowItWorksScreen()
        }.disposed(by: disposeBag)

        signInButton.rx.tap.bind {
            viewModel.goToSignInScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: Setup views
    override func setupViews() {
        super.setupViews()

        let buttonsGroup = UIView()
        buttonsGroup.flex.direction(.column).define { (flex) in
            flex.addItem(getStartedButton).width(100%)
            flex.addItem(signInButton).width(100%).marginTop(Size.dh(20))
        }

        contentView.flex.addItem(buttonsGroup).position(.absolute).bottom(0).width(100%)
    }
}

extension SignInWallViewController {
    fileprivate func makeGetStartedButton() -> SubmitButton {
        return SubmitButton(title: R.string.localizable.getStarted())
    }

    fileprivate func makeSignInButton() -> Button {
        return SecondaryButton(title: R.string.localizable.signIn())
    }
}
