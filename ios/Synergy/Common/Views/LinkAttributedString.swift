//
//  LinkAttributedString.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

class LinkAttributedString {
    static func make(
        string: String,
        lineHeight: CGFloat? = nil,
        attributes: [NSAttributedString.Key: Any] = [:],
        links: [(text: String, url: String)] = [],
        linkAttributes: [NSAttributedString.Key: Any] = [:]) -> NSMutableAttributedString {

        let attributedText = NSMutableAttributedString(
            string: string,
            attributes: attributes
        )

        links.forEach { (text, url) in
            guard let range = string.range(of: text) else { return }
            var linkAttributes = linkAttributes
            linkAttributes[.link] = url
            attributedText.addAttributes(linkAttributes, range: text.nsRange(from: range))
        }

        if let lineHeight = lineHeight {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = lineHeight

            attributedText.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: attributedText.length))
        }

        return attributedText
    }
}
