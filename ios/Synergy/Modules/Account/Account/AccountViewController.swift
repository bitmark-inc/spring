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
    lazy var screenTitle = makeScreenTitle()

    lazy var signOutOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSecuritySignOut())
    lazy var faceIDOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSecurityFaceID())
    lazy var recoveryKeyOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSecurityRecoveryKey())

    lazy var aboutOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportAbout())
    lazy var faqOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportFaq())
    lazy var contactOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportContact())

    override func bindViewModel() {
        super.bindViewModel()

        signOutOptionButton.rx.tap.bind { [weak self] in
            self?.gotoSignOutFlow()
        }.disposed(by: disposeBag)

        faceIDOptionButton.rx.tap.bind { [weak self] in
            self?.gotoFaceIDFlow()
        }.disposed(by: disposeBag)

        recoveryKeyOptionButton.rx.tap.bind { [weak self] in
            self?.gotoViewRecoveryKeyFlow()
        }.disposed(by: disposeBag)

        aboutOptionButton.rx.tap.bind { [weak self] in
            self?.gotoAboutScreen()
        }.disposed(by: disposeBag)

        faqOptionButton.rx.tap.bind { [weak self] in
            self?.gotoFAQScreen()
        }.disposed(by: disposeBag)

        contactOptionButton.rx.tap.bind { [weak self] in
            self?.showIntercomContact()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        contentView.flex.direction(.column)
            .define { (flex) in
                flex.addItem().marginLeft(OurTheme.paddingInset.left).define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).padding(OurTheme.paddingInset)
                }

                flex.addItem(
                    makeOptionsSection(
                        name: R.string.phrase.accountSettingsSecurity(),
                        options: [signOutOptionButton, faceIDOptionButton, recoveryKeyOptionButton]))
                    .marginTop(12)

                flex.addItem(
                    makeOptionsSection(
                        name: R.string.phrase.accountSettingsSupport(),
                        options: [aboutOptionButton, faqOptionButton, contactOptionButton]))
                    .marginTop(12)
            }

    }
}

// MARK: - Navigator
extension AccountViewController {
    fileprivate func gotoSignOutFlow() {
        navigator.show(segue: .signOutWarning, sender: self)
    }

    fileprivate func gotoFaceIDFlow() {

    }

    fileprivate func gotoViewRecoveryKeyFlow() {
        navigator.show(segue: .viewRecoveryKeyWarning, sender: self)
    }

    fileprivate func gotoAboutScreen() {
        navigator.show(segue: .about, sender: self)
    }

    fileprivate func gotoFAQScreen() {
        navigator.show(segue: .faq, sender: self)
    }

    fileprivate func showIntercomContact() {
        Intercom.presentMessenger()
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
        nameSectionLabel.applyBlack(text: name.localizedUppercase, font: R.font.atlasGroteskLight(size: Size.ds(24)))

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
}
