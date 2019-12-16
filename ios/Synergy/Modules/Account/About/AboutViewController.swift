//
//  AboutViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class AboutViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()

    override func bindViewModel() {
        super.bindViewModel()
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()
        let descriptionTextView = makeDescriptionTextView()

        contentView.flex
            .direction(.column)
            .define { (flex) in
                flex.addItem().padding(OurTheme.paddingInset).define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                }

                flex.addItem(descriptionTextView)
            }
    }
}

extension AboutViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountAboutTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeDescriptionTextView() -> UITextView {
        let textView = UITextView()
        textView.text = R.string.phrase.accountAboutDescription()
        textView.font = R.font.atlasGroteskThin(size: Size.ds(22))
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textContainerInset = OurTheme.scrollingPaddingInset
        themeService.rx
            .bind({ $0.tundoraTextColor }, to: textView.rx.textColor)
            .disposed(by: disposeBag)

        return textView
    }
}
