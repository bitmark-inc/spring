//
//  ConfirmRecoveryKeyViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class ConfirmRecoveryKeyViewController: ViewController {

    // MARK: - Properties
    lazy var recoveryKeyTextView = makeRecoveryKeyTextView()
    lazy var guideLabel = makeGuideLabel()
    lazy var submitButton = makeSignOutButton()
    lazy var recoveryKeyView = makeRecoveryKeyView()

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ConfirmRecoveryKeyViewModel else { return }

        viewModel.submitEnabled
            .drive(submitButton.rx.isEnabled)
            .disposed(by: disposeBag)

        _ = recoveryKeyTextView.rx.textInput => viewModel.recoveryKeyStringRelay
    }
}

// MARK: - UITextViewDelegate
extension ConfirmRecoveryKeyViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
      if text == "\n" {
        textView.resignFirstResponder()
      }
      return true
    }
}

extension ConfirmRecoveryKeyViewController {
    fileprivate func makeRecoveryKeyView() -> UIView {
        let view = UIView()
        view.flex.direction(.column).define { (flex) in
            flex.addItem(recoveryKeyTextView).height(Size.dh(145))
            flex.addItem(guideLabel).marginTop(Size.dh(27))
        }
        return view
    }

    fileprivate func makeRecoveryKeyTextView() -> UITextView {
        let textView = UITextView()
        textView.font = R.font.atlasGroteskLight(size: Size.ds(22))
        textView.autocapitalizationType = .none
        textView.returnKeyType = .done
        textView.delegate = self
        textView.borderWidth = 1
        textView.contentInset = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 21)

        themeService.rx
            .bind({ $0.blackTextColor }, to: textView.rx.borderColor)
            .bind({ $0.blackTextColor }, to: textView.rx.textColor)
            .bind({ $0.blackTextColor }, to: textView.rx.tintColor)
            .disposed(by: disposeBag)

        return textView
    }

    fileprivate func makeGuideLabel() -> Label {
        let label = Label()
        label.isDescription = true
        label.apply(
            text: R.string.phrase.accountRecoveryKeyInputGuide(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            colorTheme: .tundora,
            lineHeight: 1.32)
        return label
    }

    fileprivate func makeSignOutButton() -> SubmitButton {
        let submitButton = SubmitButton()
        submitButton.applyTheme(colorTheme: .mercury)
        return submitButton
    }
}
