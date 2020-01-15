//
//  UsageViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Intercom

class AccountViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var settingsView = UIView()

    lazy var screenTitle = makeScreenTitle()
    lazy var signOutOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSecuritySignOut())
    lazy var biometricAuthOptionButton = makeBiometricAuthOptionButton()
    lazy var recoveryKeyOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSecurityRecoveryKey())

    lazy var increasePrivacyButton = makeOptionButton(title: R.string.phrase.accountSettingsFacebookIncreasePrivacy())

    lazy var aboutOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportAbout())
    lazy var faqOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportFaq())
    lazy var whatsNewButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportWhatsNew())
    lazy var contactOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportContact())
    lazy var surveyOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportGetYourThoughts())

    lazy var versionLabel = makeVersionLabel()
    lazy var bitmarkCertView = makeBitmarkCertView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        signOutOptionButton.rx.tap.bind { [weak self] in
            self?.gotoSignOutFlow()
        }.disposed(by: disposeBag)

        biometricAuthOptionButton?.rx.tap.bind { [weak self] in
            self?.gotoBiometricAuthFlow()
        }.disposed(by: disposeBag)

        recoveryKeyOptionButton.rx.tap.bind { [weak self] in
            self?.gotoViewRecoveryKeyFlow()
        }.disposed(by: disposeBag)

        increasePrivacyButton.rx.tap.bind { [weak self] in
            self?.gotoIncreasePrivacyListScreen()
        }.disposed(by: disposeBag)

        aboutOptionButton.rx.tap.bind { [weak self] in
            self?.gotoAboutScreen()
        }.disposed(by: disposeBag)

        faqOptionButton.rx.tap.bind { [weak self] in
            self?.gotoFAQScreen()
        }.disposed(by: disposeBag)

        whatsNewButton.rx.tap.bind { [weak self] in
            self?.gotoReleaseNoteScreen()
        }.disposed(by: disposeBag)

        contactOptionButton.rx.tap.bind { [weak self] in
            self?.showIntercomContact()
        }.disposed(by: disposeBag)

        surveyOptionButton.rx.tap.bind { [weak self] in
            self?.showSurveyLink()
        }.disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = settingsView.frame.size
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        let securityButtonGroup: [Button]!

        if let biometricAuthOptionButton = biometricAuthOptionButton {
            securityButtonGroup = [signOutOptionButton, biometricAuthOptionButton, recoveryKeyOptionButton]
        } else {
            securityButtonGroup = [signOutOptionButton, recoveryKeyOptionButton]
        }

        settingsView.flex.define { (flex) in
            flex.addItem()
                .marginLeft(OurTheme.paddingInset.left)
                .define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).padding(OurTheme.paddingInset)
                }

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsSecurity(),
                    options: securityButtonGroup))
                .marginTop(12)

            flex.addItem(
                makeOptionsSection(
                   name: R.string.phrase.accountSettingFacebook(),
                   options: [increasePrivacyButton]))
                .marginTop(12)

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsSupport(),
                    options: [whatsNewButton, contactOptionButton, surveyOptionButton]))
                .marginTop(12)

        }

        scroll.addSubview(settingsView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).grow(1)
                flex.addItem(bitmarkCertView).paddingBottom(22)
            }
    }
}

// MARK: - Navigator
extension AccountViewController {
    fileprivate func gotoSignOutFlow() {
        navigator.show(segue: .signOutWarning, sender: self)
    }

    fileprivate func gotoBiometricAuthFlow() {
        navigator.show(segue: .biometricAuth, sender: self)
    }

    fileprivate func gotoViewRecoveryKeyFlow() {
        navigator.show(segue: .viewRecoveryKeyWarning, sender: self)
    }

    fileprivate func gotoIncreasePrivacyListScreen() {
        navigator.show(segue: .increasePrivacyList, sender: self)
    }

    fileprivate func gotoAboutScreen() {
        navigator.show(segue: .about, sender: self)
    }

    fileprivate func gotoFAQScreen() {
        navigator.show(segue: .faq, sender: self)
    }

    fileprivate func gotoReleaseNoteScreen() {
        navigator.show(segue: .releaseNote(buttonItemType: .back), sender: self)
    }

    fileprivate func showIntercomContact() {
        Intercom.presentMessenger()
    }

    fileprivate func showSurveyLink() {
        navigator.show(segue: .safari(Constant.surveyURL), sender: self)
    }
}

// MARK: UITextViewDelegate
extension AccountViewController: UITextViewDelegate {
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

extension AccountViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountSettingsTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeOptionsSection(name: String, options: [Button]) -> UIView {
        let nameSectionLabel = Label()
        nameSectionLabel.apply(
            text: name.localizedUppercase,
            font: R.font.atlasGroteskLight(size: Size.ds(24)),
            colorTheme: .black)

        let sectionView = UIView()
        themeService.rx
            .bind({ $0.sectionBackgroundColor }, to: sectionView.rx.backgroundColor)
            .disposed(by: disposeBag)

        sectionView.flex
            .padding(UIEdgeInsets(top: Size.dh(18), left: OurTheme.paddingInset.left, bottom: Size.dh(18), right: OurTheme.paddingInset.right))
            .direction(.column).define { (flex) in
                flex.addItem(nameSectionLabel).marginBottom(5)
                options.forEach { flex.addItem($0).marginTop(15) }
            }

        return sectionView
    }

    fileprivate func makeOptionButton(title: String) -> Button {
        let button = Button()
        button.applyBlack(title: title, font: R.font.atlasGroteskThin(size: Size.ds(18)))
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        return button
    }

    fileprivate func makeBiometricAuthOptionButton() -> Button? {
        let currentDeviceEvaluatePolicyType = BiometricAuth.currentDeviceEvaluatePolicyType()

        guard currentDeviceEvaluatePolicyType != .none else { return nil }
        let title = R.string.phrase.accountSettingsSecurityBiometricAuth(currentDeviceEvaluatePolicyType.text)
        return makeOptionButton(title: title)
    }

    fileprivate func makeBitmarkCertView() -> UIView {
        let view = UIView()
        view.flex.alignItems(.center)
            .define { (flex) in
                flex.addItem(versionLabel)
                flex.addItem(makeTermsAndPolicyTextView()).marginTop(7)
                flex.addItem(ImageView(image: R.image.securedByBitmark())).marginTop(9)
            }
        return view
    }

    fileprivate func makeVersionLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.releaseNoteAppVersion(UserDefaults.standard.appVersion ?? "--"),
            font: R.font.atlasGroteskLight(size: Size.ds(14)), colorTheme: .black)
        return label
    }

    fileprivate func makeTermsAndPolicyTextView() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.blackTextColor
        ]

        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.termsAndPolicyPhraseInSettings(
                AppLink.termsOfService.generalText,
                AppLink.privacyOfPolicy.generalText),
            attributes: [
                .font: R.font.atlasGroteskLight(size: Size.ds(12))!,
                .foregroundColor: themeService.attrs.blackTextColor
            ], links: [
                (text: AppLink.termsOfService.generalText, url: AppLink.termsOfService.path),
                (text: AppLink.privacyOfPolicy.generalText, url: AppLink.privacyOfPolicy.path)
            ], linkAttributes: [
                .font: R.font.atlasGroteskLightItalic(size: Size.ds(12))!,
                .underlineColor: themeService.attrs.blackTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])

        return textView
    }
}
