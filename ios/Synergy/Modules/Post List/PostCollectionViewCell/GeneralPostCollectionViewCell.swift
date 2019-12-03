//
//  GeneralCollectionViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class GeneralPostCollectionViewCell: CollectionViewCell, PostDataCollectionViewCell {

    // MARK: - Properties
    fileprivate lazy var postInfoLabel = makePostInfoLabel()
    fileprivate lazy var captionLabel = makeCaptionLabel()
    fileprivate lazy var photoImageView = makePhotoImageView()
    var clickableTextDelegate: ClickableTextDelegate?

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        themeService.rx
            .bind({ $0.postCellBackgroundColor }, to: rx.backgroundColor)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().padding(12, 17, 0, 12).define { (flex) in
                flex.addItem(postInfoLabel)
                flex.addItem(captionLabel).marginTop(12).basis(1)
            }
            flex.addItem(photoImageView).marginTop(20)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        photoImageView.flex.height(0)
        invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Data
    func bindData(post: Post) {
        postInfoLabel.attributedText = makePostInfo(of: post)
        captionLabel.attributedText = LinkAttributedString.make(
            string: post.caption,
            lineHeight: 1.25,
            attributes: [.font: R.font.atlasGroteskThin(size: 16)!])
        if let photo = post.photo, let photoURL = URL(string: photo) {
            photoImageView.loadURL(photoURL)
        }

        postInfoLabel.flex.markDirty()
        captionLabel.flex.markDirty()
        photoImageView.flex.markDirty()
    }
}

extension GeneralPostCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        clickableTextDelegate?.click(textView, url: URL)
        return false
    }
}

extension GeneralPostCollectionViewCell {
    fileprivate func makePostInfoLabel() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: themeService.attrs.blackTextColor
        ]
        return textView
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

    fileprivate func makePhotoImageView() -> ImageView {
        return ImageView()
    }
}
