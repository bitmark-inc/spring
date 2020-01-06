//
//  UpdatePostTableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class UpdatePostTableViewCell: TableViewCell, PostDataTableViewCell {

    // MARK: - Properties
    fileprivate lazy var postInfoLabel = makePostInfoLabel()
    fileprivate lazy var captionLabel = makeCaptionLabel()
    weak var clickableDelegate: ClickableDelegate?

    // MARK: - Inits
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        themeService.rx
            .bind({ $0.postCellBackgroundColor }, to: rx.backgroundColor)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().padding(OurTheme.postCellPadding).define { (flex) in
                flex.addItem(postInfoLabel)
                flex.addItem(captionLabel)
            }
            flex.addItem(makeSeparator())
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Data
    func bindData(post: Post) {
        postInfoLabel.text = makePostInfo(
            timestamp: post.timestamp,
            friends: post.tags.toArray(),
            locationName: post.location?.name)

        if let caption = post.post {
            captionLabel.attributedText = LinkAttributedString.make(
                string: caption,
                lineHeight: 1.25,
                attributes: [.font: R.font.atlasGroteskLight(size: 16)!])
            captionLabel.flex.marginTop(12)
        } else {
            captionLabel.attributedText = nil
            captionLabel.flex.marginTop(0)
        }

        postInfoLabel.flex.markDirty()
        captionLabel.flex.markDirty()
        contentView.flex.layout(mode: .adjustHeight)
    }
}

extension UpdatePostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        clickableDelegate?.click(textView, url: URL)
        return false
    }
}

extension UpdatePostTableViewCell {
    fileprivate func makePostInfoLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.domaineSansTextLight(size: Size.ds(14)),
            colorTheme: .black, lineHeight: 1.3)
        return label
    }

    fileprivate func makeCaptionLabel() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        return textView
    }
}
