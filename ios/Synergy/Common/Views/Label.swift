//
//  Label.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class Label: UILabel {

    let disposeBag = DisposeBag()

    convenience init(text: String) {
        self.init()
        self.text = text
        self.lineHeightMultiple(1.2)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func makeHighlightBackground() {
        themeService.rx
            .bind({ $0.highlightTextBackgroundColor }, to: rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    func setupViews() {
        themeService.rx
            .bind({ $0.textColor }, to: rx.textColor)
            .disposed(by: disposeBag)

        font = R.font.atlasGroteskRegular(size: Size.ds(18))
    }

    func lineHeightMultiple(_ lineHeightMultiple: CGFloat) {
        let attributedString = NSMutableAttributedString(string: text ?? "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        // *** Apply attribute to string ***
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        // *** Set Attributed String to your label ***
        attributedText = attributedString
    }
}

class LightLabel: Label {
    override func setupViews() {
        themeService.rx
            .bind({ $0.lightTextColor }, to: rx.textColor)
            .disposed(by: disposeBag)

        font = R.font.atlasGroteskRegular(size: Size.ds(18))
    }
}
