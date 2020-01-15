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
    lazy var termsAndPolicyView = makeTermsAndPolicyView()
    lazy var getStartedButton = makeGetStartedButton()
    lazy var signInButton = makeSignInButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

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
        setupBackground(backgroundView: ImageView(image: R.image.onboardingSplash()))
        super.setupViews()

        contentView.backgroundColor = .clear

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.apply(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(80)),
            colorTheme: .white)

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            colorTheme: .white, lineHeight: 1.125)

        let buttonsGroup = UIView()
        buttonsGroup.flex.direction(.column).define { (flex) in
            flex.addItem(termsAndPolicyView).alignSelf(.center)
            flex.addItem(getStartedButton).width(100%).marginTop(Size.dh(17))
            flex.addItem(signInButton).width(100%).marginTop(Size.dh(20))
        }

        contentView.flex
            .padding(OurTheme.paddingInset)
            .alignItems(.center)
            .direction(.column).define { (flex) in
                flex.addItem(titleScreen).marginTop(Size.dh(123))
                flex.addItem(descriptionLabel)

                flex.addItem(buttonsGroup)
                    .position(.absolute)
                    .width(100%)
                    .left(OurTheme.paddingInset.left).bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: UITextViewDelegate
extension SignInWallViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme != nil, let host = URL.host else {
            return false
        }

        guard let appLink = AppLink(rawValue: host),
            let appLinkURL = appLink.websiteURL
        else {
            return true
        }

        navigator.show(segue: .safariController(appLinkURL), sender: self, transition: .alert)
        return true
    }
}

// MARK: - Navigator
extension SignInWallViewController {
    fileprivate func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self)
    }

    func goToSignInScreen() {
        let viewModel = SignInViewModel()
        navigator.show(segue: .signIn(viewModel: viewModel), sender: self)
    }
}

extension SignInWallViewController {
    fileprivate func makeGetStartedButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.getStarted())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeSignInButton() -> Button {
        return SecondaryButton(title: R.string.localizable.signIn())
    }

    fileprivate func makeTermsAndPolicyView() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.lightTextColor
        ]

        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.termAndPolicyPhraseInSignInWall(
                AppLink.termsOfService.generalText,
                AppLink.privacyOfPolicy.generalText),
            lineHeight: 1.3,
            attributes: [
                .font: R.font.atlasGroteskLight(size: Size.ds(12))!,
                .foregroundColor: themeService.attrs.lightTextColor
            ], links: [
                (text: AppLink.termsOfService.generalText, url: AppLink.termsOfService.path),
                (text: AppLink.privacyOfPolicy.generalText, url: AppLink.privacyOfPolicy.path)
            ], linkAttributes: [
                .font: R.font.atlasGroteskLightItalic(size: Size.ds(12))!,
                .underlineColor: themeService.attrs.lightTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])

        return textView
    }
}
