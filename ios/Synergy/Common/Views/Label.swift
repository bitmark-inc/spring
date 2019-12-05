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

    var lineHeight: CGFloat?

    var isDescription: Bool = false {
        didSet {
            if isDescription {
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
        paragraphStyle.alignment = isDescription ? .center : .left

        // *** Apply attribute to string ***
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        // *** Set Attributed String to your label ***
        attributedText = attributedString
    }
}

extension Label {
    func setText(_ text: String) {
        self.text = text

        if let lineHeight = lineHeight {
            lineHeightMultiple(lineHeight)
        }
        flex.markDirty()
    }

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

    func applyBlack(text: String, font: UIFont?, lineHeight: CGFloat? = nil, level: Int = 0) {
        self.text = text
        self.font = font

        switch level {
        case 1:
            themeService.rx
                .bind({ $0.black1TextColor }, to: rx.textColor)
                .disposed(by: disposeBag)

        case 2:
            themeService.rx
                .bind({ $0.black2TextColor }, to: rx.textColor)
                .disposed(by: disposeBag)

        case 3:
            themeService.rx
                .bind({ $0.themeColor }, to: rx.textColor)
                .disposed(by: disposeBag)

        default:
            themeService.rx
                .bind({ $0.blackTextColor }, to: rx.textColor)
                .disposed(by: disposeBag)
        }

        if let lineHeight = lineHeight {
            self.lineHeight = lineHeight
            lineHeightMultiple(lineHeight)
        }
    }
}

extension Label {
    static func create(withFont font: UIFont?) -> Label {
        let l = Label()
        l.font = font
        return l
    }
}
