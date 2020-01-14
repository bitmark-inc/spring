//
//  SignOutWarningViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class SignOutWarningViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var attributedDescriptionTextView = makeAttributedDescriptionTextView()
    lazy var continueButton = makeContinueButton()
    fileprivate var lockTextViewClick: Bool = false // for unknown reason, textview delegate function call more than 1 times

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockTextViewClick = false
    }

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.gotoSignOutScreen()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem().define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).margin(OurTheme.accountPaddingScreenTitleInset)
                    flex.addItem(attributedDescriptionTextView)
                }

                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - UITextViewDelegate
extension SignOutWarningViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !lockTextViewClick else { return false }
        lockTextViewClick = true
        
        guard URL.scheme != nil, let host = URL.host else {
            lockTextViewClick = false
            return false
        }
        
        switch host {
        case "view-recovery-key":
            gotoViewRecoveryKeyFlow()
        default:
            lockTextViewClick = false
            return false
        }
        return true
    }
}

// MARK: - Navigator
extension SignOutWarningViewController {
    fileprivate func gotoViewRecoveryKeyFlow() {
        navigator.show(segue: .viewRecoveryKeyWarning, sender: self)
    }

    fileprivate func gotoSignOutScreen() {
        let viewModel = SignOutViewModel()
        navigator.show(segue: .signOut(viewModel: viewModel), sender: self)
    }
}

extension SignOutWarningViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountSignOutTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeAttributedDescriptionTextView() -> UITextView {
        let linkToViewRecoveryKeyText = R.string.phrase.accountSignOutWarningDescriptionLinkToViewRecoveryKey()
        let description = R.string.phrase.accountSignOutWarningDescription(linkToViewRecoveryKeyText)

        let attributedDescription = LinkAttributedString.make(
            string: description,
            lineHeight: 1.32,
            attributes: [
                .font: R.font.atlasGroteskThin(size: Size.ds(22))!,
                .foregroundColor: themeService.attrs.tundoraTextColor
            ],
            links: [
                (text: linkToViewRecoveryKeyText, url: "\(Constant.appName)://view-recovery-key")
            ],
            linkAttributes: [
              .underlineColor: themeService.attrs.tundoraTextColor,
              .underlineStyle: NSUnderlineStyle.single.rawValue,
              .foregroundColor: themeService.attrs.tundoraTextColor
            ])

        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.tundoraTextColor
        ]
        textView.attributedText = attributedDescription
        return textView
    }

    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continue().localizedUppercase)
        submitButton.applyTheme(colorTheme: .mercury)
        return submitButton
    }
}
