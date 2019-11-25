//
//  GetYourDataViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/20/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa

class GetYourDataViewController: ViewController, BackNavigator {

    // MARK: - Properties
    var form: UIView!
    var loginTextField: TextField!
    var passwordTextField: TextField!
    var manualAuthorizeBtn: Button!
    var automateAuthorizeBtn: Button!

    // MARK: - Setup Views
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.layoutIfNeeded()
        contentView.flex.layout()
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? GetYourDataViewModel else { return }

        _ = loginTextField.rx.textInput => viewModel.loginRelay
        _ = passwordTextField.rx.textInput => viewModel.passwordRelay

        viewModel.automateAuthorizeBtnEnabled
            .drive(automateAuthorizeBtn.rx.isEnabled)
            .disposed(by: disposeBag)

        automateAuthorizeBtn.rx.tap.bind {
            viewModel.gotoRequestData()
        }.disposed(by: disposeBag)

        viewModel.loginRelay.accept(loginTextField.text!)
        viewModel.passwordRelay.accept(passwordTextField.text!)
    }

    override func setupViews() {
        setupBackground(image: R.image.cognacBackground())
        super.setupViews()

        showLightBackItem()
        setLightScreenTitle(text: R.string.phrase.getYourDataScreenTitle().localizedUppercase)

        loginTextField = TextFieldWithRightIcon(rightIcon: R.image.lock())
        loginTextField.placeholder = R.string.phrase.getYourDataLoginPlaceholder()

        passwordTextField = TextFieldWithRightIcon(rightIcon: R.image.lock())
        passwordTextField.placeholder = R.string.phrase.getYourDataPasswordPlaceholder()
        passwordTextField.isSecureTextEntry = true

        form = UIView()
        form.flex.direction(.column).define { (flex) in
            flex.addItem(loginTextField).height(50)
            flex.addItem(passwordTextField).height(50).marginTop(Size.dh(19))
        }

        let giveAutomateTrust = Label()
        giveAutomateTrust.isDescription = true
        giveAutomateTrust.applyLight(
            text: R.string.phrase.getYourDataGiveAutomateTrust(),
            font: R.font.atlasGroteskRegular(size: Size.ds(18)),
            lineHeight: 1.2
        )

        manualAuthorizeBtn = Button()
        manualAuthorizeBtn.contentHorizontalAlignment = .left
        manualAuthorizeBtn.applyUnderlinedLight(
            title: R.string.phrase.getYourDataAuthorizeManual(),
            font: R.font.atlasGroteskThin(size: Size.ds(14))
        )

        automateAuthorizeBtn = Button()
        automateAuthorizeBtn.applyLight(
            title: R.string.phrase.getYourDataAuthorizeAutomate(),
            font: R.font.atlasGroteskRegular(size: 18)
        )

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(form)
            flex.addItem(giveAutomateTrust).marginTop(Size.dh(35))
            flex.addItem(manualAuthorizeBtn).marginTop(Size.dh(35))
            automateAuthorizeBtn.flex.position(.absolute).bottom(0)
            flex.addItem(automateAuthorizeBtn).width(100%)
        }
    }
}
