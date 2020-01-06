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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? GetYourDataViewModel else { return }

        _ = loginTextField.rx.textInput => viewModel.loginRelay
        _ = passwordTextField.rx.textInput => viewModel.passwordRelay

        viewModel.automateAuthorizeBtnEnabled
            .drive(automateAuthorizeButton.rx.isEnabled)
            .disposed(by: disposeBag)

        automateAuthorizeButton.rx.tap.bind { [weak self] in
            _ = connectedToInternet()
                .subscribe(onCompleted: { [weak self] in
                    viewModel.saveFBCredentialToKeychain()
                    self?.gotoRequestData()
                })
        }.disposed(by: disposeBag)

        viewModel.loginRelay.accept(loginTextField.text!)
        viewModel.passwordRelay.accept(passwordTextField.text!)

        viewModel.resultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .completed:
                    self.gotoDataAnalyzing()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // clear credential inputs
        guard let viewModel = viewModel as? GetYourDataViewModel else { return }
        viewModel.passwordRelay.accept("")
        passwordTextField.text = nil
    }

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorTheme.cognac.color
        return view
    }()

    // MARK: - Setup Views
    override func setupViews() {
        setupBackground(backgroundView: backgroundView)
        super.setupViews()

        let screenTitle = Label()
        screenTitle.applyTitleTheme(
            text: R.string.phrase.getYourDataScreenTitle().localizedUppercase,
            colorTheme: .white)

        let giveAutomateTrust = Label()
        giveAutomateTrust.numberOfLines = 0
        giveAutomateTrust.applyLight(
            text: R.string.phrase.getYourDataGiveAutomateTrust(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.32)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(screenTitle).marginTop(OurTheme.onboardingPaddingScreenTitle)
                flex.addItem().marginTop(Size.dh(45))
                    .direction(.column).define { (flex) in
                        flex.addItem(loginTextField).height(50)
                        flex.addItem(passwordTextField).height(50).marginTop(Size.dh(19))
                    }

                flex.addItem(giveAutomateTrust).marginTop(Size.dh(35))

//                flex.addItem(manualAuthorizeButton).marginTop(Size.dh(35))
                flex.addItem(automateAuthorizeButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension GetYourDataViewController {
    fileprivate func gotoRequestData() {
        guard let viewModel = viewModel as? GetYourDataViewModel else { return }
        let requestDataViewModel = RequestDataViewModel(
            login: viewModel.loginRelay.value,
            password: viewModel.passwordRelay.value,
            .requestData)
        navigator.show(segue: .requestData(viewModel: requestDataViewModel), sender: self)
    }

    fileprivate func gotoDataAnalyzing() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self)
    }
}

extension GetYourDataViewController {
    fileprivate func makeLoginTextField() -> TextField {
        let textfield = TextFieldWithRightIcon(rightIcon: R.image.lock())
        textfield.textContentType = .username
        textfield.set(placeholder: R.string.phrase.getYourDataLoginPlaceholder())
        textfield.autocapitalizationType = .none
        textfield.returnKeyType = .done
        return textfield
    }

    fileprivate func makePasswordTextField() -> TextField {
        let textfield = TextFieldWithRightIcon(rightIcon: R.image.lock())
        textfield.set(placeholder: R.string.phrase.getYourDataPasswordPlaceholder())
        textfield.textContentType = .password
        textfield.isSecureTextEntry = true
        textfield.returnKeyType = .done
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

    fileprivate func makeAutomateAuthorizeButton() -> SubmitButton {
        let button = SubmitButton(title: R.string.phrase.getYourDataAuthorizeAutomate())
        button.applyTheme(colorTheme: .indianKhaki)
        return button
    }
}
