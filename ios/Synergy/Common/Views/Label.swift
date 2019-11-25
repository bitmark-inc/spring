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

    var isDescription: Bool = false {
        didSet {
            if self.isDescription {
                numberOfLines = 0
                textAlignment = .center
            } else {
                numberOfLines = 1
                textAlignment = .left
            }
        }
    }

    let disposeBag = DisposeBag()

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

extension Label {
    func applyLight(text: String, font: UIFont?, lineHeight: CGFloat? = nil) {
        self.text = text
        self.font = font

        themeService.rx
            .bind({ $0.lightTextColor }, to: rx.textColor)
            .disposed(by: disposeBag)

        if let lineHeight = lineHeight {
            lineHeightMultiple(lineHeight)
        }
    }

    func applyBlack(text: String, font: UIFont?, lineHeight: CGFloat? = nil) {
        self.text = text
        self.font = font

        themeService.rx
            .bind({ $0.blackTextColor }, to: rx.textColor)
            .disposed(by: disposeBag)

        if let lineHeight = lineHeight {
            lineHeightMultiple(lineHeight)
        }
    }
}
