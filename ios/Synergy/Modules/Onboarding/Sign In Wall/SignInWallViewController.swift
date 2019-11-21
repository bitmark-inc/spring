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

class SignInWallViewController: ViewController {

    lazy var thisViewModel = { viewModel as! SignInWallViewModel }()

    // MARK: - Properties
    var registerButton: SubmitButton!
    var signInButton: UIButton!

    // MARK: Handlers
    override func bindViewModel() {
        super.bindViewModel()

        registerButton.rx.tap.bind { [weak self] in
            self?.thisViewModel.goToSignUpScreen()
        }.disposed(by: disposeBag)

        signInButton.rx.tap.bind { [weak self] in
            self?.thisViewModel.goToSignInScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: Setup views
    override func setupViews() {
        super.setupViews()

        let backgroundImage = ImageView(image: R.image.onboardingSplash())
        backgroundImage.contentMode = .scaleToFill

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.font = R.font.domaineSansTextRegular(size: Size.ds(60))
        titleScreen.text = Constant.appName.uppercased()
        titleScreen.makeHighlightBackground()

        let descriptionLabel = DescriptionLabel(text: R.string.phrase.signinWallDescription())

        registerButton = SubmitButton(title: R.string.localizable.getStarted())
        signInButton = SecondaryButton(title: R.string.localizable.signIn())

        let buttonsGroupStackView = UIStackView(
            arrangedSubviews: [registerButton, signInButton],
            axis: .vertical,
            spacing: Size.dh(40)
        )

        // *** Setup UI in view ***
        view.addSubview(backgroundImage)
        view.addSubview(titleScreen)
        view.addSubview(descriptionLabel)
        view.addSubview(buttonsGroupStackView)

        backgroundImage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        titleScreen.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleScreen.snp.bottom).offset(Size.dh(20))
            make.centerX.equalToSuperview()
        }

        buttonsGroupStackView.snp.makeConstraints { (make) in
            make.width.equalTo(Size.dw(325))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Size.dh(48))
        }
    }
}
