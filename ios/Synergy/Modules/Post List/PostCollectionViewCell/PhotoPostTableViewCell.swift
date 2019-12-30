//
//  PhotoPostTableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class PhotoPostTableViewCell: TableViewCell, PostDataTableViewCell {

    // MARK: - Properties
    fileprivate lazy var postInfoLabel = makePostInfoLabel()
    fileprivate lazy var captionLabel = makeCaptionLabel()
    fileprivate lazy var photosView = UIView()
    lazy var photoWidth: CGFloat = {
        return UIScreen.main.bounds.width - (OurTheme.postCellPadding.left + OurTheme.postCellPadding.right)
    }()
    var post: Post?
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
                flex.addItem(photosView).width(100%)
            }
            flex.addItem(makeSeparator())
        }

        contentView.flex.layout(mode: .adjustHeight)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        photosView.removeSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Data
    func bindData(post: Post) {
        self.post = post
        makePostInfo(timestamp: post.timestamp, friends: post.tags.toArray(), locationName: post.location?.name)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                self?.postInfoLabel.attributedText = $0
            })
            .disposed(by: disposeBag)

        if let caption = post.post {
            captionLabel.attributedText = LinkAttributedString.make(
                string: caption,
                lineHeight: 1.25,
                attributes: [.font: R.font.atlasGroteskLight(size: 16)!])
            captionLabel.flex.marginTop(12)
        }

        postInfoLabel.flex.markDirty()
        captionLabel.flex.markDirty()

        loadImage()
        photosView.flex.markDirty()
        contentView.flex.layout(mode: .adjustHeight)
    }

    func loadImage() {
        guard let post = post else { return }
        for media in post.mediaData {
            let photoImageView = makePhotoImageView()
            self.photosView.flex.define { (flex) in
                flex.addItem().height(20).backgroundColor(.clear)
                flex.addItem(photoImageView).width(photoWidth).height(photoWidth)
            }

            if let photoURL = URL(string: media.source) {
                photoImageView.loadURL(photoURL, width: photoWidth)
                    .subscribe(onError: { (error) in
                        guard !AppError.errorByNetworkConnection(error) else { return }
                        Global.log.error(error)
                        photoImageView.image = R.image.defaultThumbnail()
                    })
                    .disposed(by: disposeBag)
            } else {
                photoImageView.image = R.image.defaultThumbnail()
            }
        }
    }
}

extension PhotoPostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        clickableDelegate?.click(textView, url: URL)
        return false
    }
}

extension PhotoPostTableViewCell {
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
        let imageView = ImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
}
