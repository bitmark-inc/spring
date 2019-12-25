//
//  TrustIsCriticalViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class TrustIsCriticalViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var continueButton = makeContinueButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.gotoAskNotificationsScreen()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        let titleScreen = Label()
        titleScreen.applyBlack(
            text: R.string.phrase.trustIsCriticalTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(34)))
        
        let contentLabel = Label()
        contentLabel.numberOfLines = 0
        contentLabel.applyBlack(
            text: R.string.phrase.trustIsCriticalDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.32
        )
        
        let sincerelyLabel = Label()
        sincerelyLabel.applyBlack(
            text: R.string.phrase.trustIsCriticalSincerely(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)))
        
        let seanSignature = ImageView(image: R.image.sean_sig())
        seanSignature.contentMode = .left
        let seanTitleLabel = Label()
        seanTitleLabel.numberOfLines = 0
        seanTitleLabel.applyBlack(
            text: R.string.phrase.trustIsCriticalTitleSignature(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.32)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(blackBackItem)

                flex.addItem(titleScreen).marginTop(Size.dh(100))
                flex.addItem(contentLabel).marginTop(Size.dh(30))
                flex.addItem(sincerelyLabel).marginTop(Size.dh(50))
                flex.addItem(seanSignature)
                flex.addItem(seanTitleLabel)
                
                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension TrustIsCriticalViewController {
    func gotoAskNotificationsScreen() {
        let viewModel = AskNotificationsViewModel()
        navigator.show(segue: .askNotifications(viewModel: viewModel), sender: self)
    }
}

extension TrustIsCriticalViewController {
    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continueArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }
}
