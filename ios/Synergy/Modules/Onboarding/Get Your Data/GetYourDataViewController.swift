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
    lazy var loginTextField = makeLoginTextField()
    lazy var passwordTextField = makePasswordTextField()
    lazy var manualAuthorizeButton = makeManualAuthorizeButton()
    lazy var automateAuthorizeButton = makeAutomateAuthorizeButton()

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
            .drive(automateAuthorizeButton.rx.isEnabled)
            .disposed(by: disposeBag)

        automateAuthorizeButton.rx.tap.bind {
            viewModel.fakeCreateAccountAndgotoAnalyzingScreen()
        }.disposed(by: disposeBag)

        viewModel.loginRelay.accept(loginTextField.text!)
        viewModel.passwordRelay.accept(passwordTextField.text!)
    }

    override func setupViews() {
        setupBackground(image: R.image.cognacBackground())
        super.setupViews()

        showLightBackItem()
        setLightScreenTitle(text: R.string.phrase.getYourDataScreenTitle().localizedUppercase)

        let giveAutomateTrust = Label()
        giveAutomateTrust.numberOfLines = 0
        giveAutomateTrust.applyLight(
            text: R.string.phrase.getYourDataGiveAutomateTrust(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().direction(.column).define { (flex) in
                flex.addItem(loginTextField).height(50)
                flex.addItem(passwordTextField).height(50).marginTop(Size.dh(19))
            }

            flex.addItem(giveAutomateTrust).marginTop(Size.dh(35))

            flex.addItem(manualAuthorizeButton).marginTop(Size.dh(35))
            flex.addItem(automateAuthorizeButton).width(100%).position(.absolute).bottom(0)
        }
    }
}

extension GetYourDataViewController {
    fileprivate func makeLoginTextField() -> TextField {
        let textfield = TextFieldWithRightIcon(rightIcon: R.image.lock())
        textfield.textContentType = .username
        textfield.set(placeholder: R.string.phrase.getYourDataLoginPlaceholder())
        return textfield
    }

    fileprivate func makePasswordTextField() -> TextField {
        let textfield = TextFieldWithRightIcon(rightIcon: R.image.lock())
        textfield.set(placeholder: R.string.phrase.getYourDataPasswordPlaceholder())
        textfield.textContentType = .password
        textfield.isSecureTextEntry = true
        return textfield
    }

    fileprivate func makeManualAuthorizeButton() -> Button {
        let button = Button()
        button.contentHorizontalAlignment = .left
        button.applyUnderlinedLight(
            title: R.string.phrase.getYourDataAuthorizeManual(),
            font: R.font.atlasGroteskLight(size: Size.ds(14)))
        return button
    }

    fileprivate func makeAutomateAuthorizeButton() -> Button {
        let button = Button()
        button.applyLight(
            title: R.string.phrase.getYourDataAuthorizeAutomate(),
            font: R.font.atlasGroteskLight(size: 18))
        return button
    }
}
