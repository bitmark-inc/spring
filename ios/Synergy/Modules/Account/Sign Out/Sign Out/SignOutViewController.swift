//
//  SignOutViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class SignOutViewController: ConfirmRecoveryKeyViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? SignOutViewModel else { return }

        viewModel.signOutAccountResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenSignOutAccount(error: error)
                case .completed:
                    Global.log.info("[done] signOut Account")
                    self.gotoOnboardingScreen()
                default:
                    break
                }
            }).disposed(by: disposeBag)

        submitButton.rx.tap.bind {
            viewModel.signOutAccount()
        }.disposed(by: disposeBag)
    }

    // MARK: - Error Handlers
    func errorWhenSignOutAccount(error: Error) {
        if let error = error as? AccountError, error == .invalidRecoveryKey {
            errorRecoveryKeyView.isHidden = false
            return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.accountSignOutError())
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        var paddingScreenTitleInset = OurTheme.accountPaddingScreenTitleInset
        paddingScreenTitleInset.bottom = 15

        submitButton.setTitle(R.string.phrase.accountSignOutSubmitTitle().localizedUppercase, for: .normal)

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
extension SignOutViewController {
    fileprivate func gotoOnboardingScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}

extension SignOutViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountSignOutTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }
}
