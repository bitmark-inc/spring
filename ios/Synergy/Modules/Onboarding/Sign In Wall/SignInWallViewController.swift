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
    var registerButton: SubmitButton!
    var signInButton: UIButton!

    // MARK: Handlers
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? SignInWallViewModel else { return }

        viewModel.signUpResultSubject.subscribe(onNext: { [weak self] (event) in
            guard let self = self else { return }
            switch event {
            case .error(let error):
                self.errorWhenSignUp(error: error)
            case .completed:
                Global.log.info("[done] signUp")
                viewModel.gotoHowItWorksScreen()
            default:
                break
            }
        }).disposed(by: disposeBag)

        registerButton.rx.tap.bind {
            viewModel.signUp()
        }.disposed(by: disposeBag)

        signInButton.rx.tap.bind {
            viewModel.goToSignInScreen()
        }.disposed(by: disposeBag)
    }

    fileprivate func errorWhenSignUp(error: Error) {
        guard !FlowError.errorByNetworkConnection(error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: "artist.create.error".localized(tableName: "Error"))
    }

    // MARK: Setup views
    override func setupViews() {
        super.setupViews()

        // *** Setup subviews ***
        registerButton = SubmitButton(title: R.string.localizable.getStarted())
        signInButton = SecondaryButton(title: R.string.localizable.signIn())

        let buttonsGroup = UIView()
        buttonsGroup.flex.direction(.column).define { (flex) in
            flex.addItem(registerButton).width(100%)
            flex.addItem(signInButton).width(100%).marginTop(Size.dh(20))
        }

        contentView.flex.addItem(buttonsGroup).position(.absolute).bottom(0).width(100%)
    }
}
