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

class SignInWallViewController: ViewController {

    // MARK: - Properties
    lazy var getStartedButton = makeGetStartedButton()
    lazy var signInButton = makeSignInButton()

    // MARK: Handlers
    override func bindViewModel() {
        super.bindViewModel()

        getStartedButton.rx.tap.bind { [weak self] in
            self?.gotoHowItWorksScreen()
        }.disposed(by: disposeBag)

        signInButton.rx.tap.bind { [weak self] in
            self?.goToSignInScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: Setup views
    override func setupViews() {
        setupBackground(image: R.image.onboardingSplash())
        super.setupViews()

        contentView.backgroundColor = .clear

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.applyLight(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(150)))
        titleScreen.adjustsFontSizeToFitWidth = true

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.applyLight(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            lineHeight: 1.1)

        let buttonsGroup = UIView()
        buttonsGroup.flex.direction(.column).define { (flex) in
            flex.addItem(getStartedButton).width(100%)
            flex.addItem(signInButton).width(100%).marginTop(Size.dh(20))
        }

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(titleScreen).marginTop(Size.dh(380)).width(100%)
                flex.addItem(descriptionLabel).marginTop(Size.dh(10))

                flex.addItem(buttonsGroup)
                    .position(.absolute)
                    .width(100%)
                    .left(OurTheme.paddingInset.left).bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension SignInWallViewController {
    fileprivate func gotoHowItWorksScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel), sender: self)
    }

    func goToSignInScreen() {
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
