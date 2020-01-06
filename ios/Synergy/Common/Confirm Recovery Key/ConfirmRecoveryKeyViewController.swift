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
    lazy var recoveryKeyBox = makeRecoveryKeyBox()
    lazy var recoveryKeyTextView = makeRecoveryKeyTextView()
    lazy var guideLabel = makeGuideLabel()
    lazy var submitButton = makeSignOutButton()
    lazy var errorRecoveryKeyView = makeErrorRecoveryView()
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
            flex.addItem(recoveryKeyBox)
            flex.addItem(guideLabel).marginTop(Size.dh(27))
        }
        return view
    }

    fileprivate func makeRecoveryKeyBox() -> UIView {
        let view = UIView()

        view.flex
            .height(Size.dh(145))
            .define { (flex) in
                let boxImage = ImageView(image: R.image.recoveryInputBox())
                boxImage.contentMode = .scaleToFill
                flex.addItem(boxImage).grow(1).width(100%).height(100%)
                    .position(.absolute)
                    .top(0)

                flex.addItem()
                    .padding(UIEdgeInsets(top: Size.dh(10), left: Size.dw(10), bottom: Size.dh(10), right: Size.dw(10)))
                    .define { (flex) in
                         flex.addItem(recoveryKeyTextView).width(100%).height(100%)
                }
        }

        themeService.rx
            .bind({ $0.blackTextColor }, to: view.rx.borderColor)
            .disposed(by: disposeBag)

        return view
    }

    fileprivate func makeRecoveryKeyTextView() -> UITextView {
        let textView = UITextView()
        textView.font = R.font.atlasGroteskLight(size: Size.ds(22))
        textView.autocapitalizationType = .none
        textView.returnKeyType = .done
        textView.delegate = self
        textView.backgroundColor = .clear

        themeService.rx
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

    fileprivate func makeErrorRecoveryView() -> UIView {
        let view = UIView()

        let titleLabel = Label()
        titleLabel.isDescription = true
        titleLabel.apply(
            text: R.string.error.signInIncorrectRecoveryKeyTitle(),
            font: R.font.atlasGroteskRegular(size: Size.ds(18)),
            colorTheme: .black)

        let descriptionLabel = Label()
        descriptionLabel.isDescription = true
        descriptionLabel.apply(
            text: R.string.error.signInIncorrectRecoveryKeyDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            colorTheme: .black, lineHeight: 1.2)

        view.flex.alignSelf(.center).define { (flex) in
            flex.addItem(titleLabel)
            flex.addItem(descriptionLabel).marginTop(9)
        }
        view.isHidden = true
        return view
    }
}
