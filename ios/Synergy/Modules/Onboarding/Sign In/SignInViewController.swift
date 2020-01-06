//
//  SignInViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import BitmarkSDK

class SignInViewController: ConfirmRecoveryKeyViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? SignInViewModel else { return }

        viewModel.signInResultSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenSignInAccount(error: error)
                case .next(let archiveStatus):
                    Global.log.info("[done] signIn Account")
                    if let archiveStatus = archiveStatus {
                        switch archiveStatus {
                        case .processed:
                            self.gotoMainScreen()
                        default:
                            self.gotoDataAnalyzingScreen()
                        }
                    } else {
                        self.gotoHowItWorksScreen()
                    }
                default:
                    break
                }
            }).disposed(by: disposeBag)

        submitButton.rx.tap.bind {
            viewModel.signInAccount()
        }.disposed(by: disposeBag)
    }

    // MARK: - Error Handlers
    func errorWhenSignInAccount(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        if let error = error as? ServerAPIError {
            switch error.code {
            case .AccountNotFound:
                gotoHowItWorksScreen()
                return
            default:
                break
            }
        }

        if type(of: error) == RecoverPhrase.RecoverPhraseError.self {
            errorRecoveryKeyView.isHidden = false
            return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.signInError())
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        var paddingScreenTitleInset = OurTheme.accountPaddingScreenTitleInset
        paddingScreenTitleInset.bottom = 15

        submitButton.setTitle(R.string.phrase.signInSubmitButton(), for: .normal)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem().define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).margin(paddingScreenTitleInset)
                    flex.addItem(recoveryKeyView)
                }

                flex.addItem()
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
                    .define { (flex) in
                        flex.addItem(errorRecoveryKeyView)
                        flex.addItem(submitButton).marginTop(Size.dh(24))
                    }
            }
    }
}

// MARK: - Navigator
extension SignInViewController {
    fileprivate func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self, transition: .replace(type: .auto))
    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .auto))
    }

    func gotoDataAnalyzingScreen() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self, transition: .replace(type: .auto))
    }
}

extension SignInViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.signInTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }
}
