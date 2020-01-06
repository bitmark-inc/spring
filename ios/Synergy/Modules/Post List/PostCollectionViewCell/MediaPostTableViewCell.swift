//
//  MediaPostTableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class MediaPostTableViewCell: TableViewCell, PostDataTableViewCell {

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

        contentView.flex.direction(.column)
            .define { (flex) in
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
        postInfoLabel.text = makePostInfo(
            timestamp: post.timestamp,
            friends: post.tags.toArray(),
            locationName: post.location?.name)

        if let caption = post.post, caption.isNotEmpty {
            captionLabel.attributedText = LinkAttributedString.make(
                string: caption,
                lineHeight: 1.25,
                attributes: [.font: R.font.atlasGroteskLight(size: 16)!])
            captionLabel.flex.marginTop(12)
            captionLabel.flex.maxHeight(100%)
        } else {
            captionLabel.attributedText = nil
            captionLabel.flex.marginTop(0)
            captionLabel.flex.maxHeight(0)
        }

        postInfoLabel.flex.markDirty()
        captionLabel.flex.markDirty()
        loadImage()

        contentView.flex.layout(mode: .adjustHeight)
    }

    func loadImage() {
        guard let post = post else { return }
        for media in post.mediaData {
            let photoImageView = addMediaView(media: media)

            if media.mediaSource == .video {
                if let thumbnail = media.thumbnail, let thumbnailURL = URL(string: thumbnail), thumbnailURL.pathExtension != "mp4" {
                    photoImageView.loadURL(thumbnailURL, width: photoWidth)
                        .subscribe(onError: { [weak self] (error) in
                            guard !AppError.errorByNetworkConnection(error) else { return }

                            self?.clickableDelegate?.errorWhenLoadingMedia(error: error)
                            photoImageView.image = R.image.defaultThumbnail()
                        })
                        .disposed(by: disposeBag)
                } else {
                    photoImageView.image = R.image.defaultThumbnail()
                }
            } else {
                if let photoURL = URL(string: media.source) {
                    photoImageView.loadURL(photoURL, width: photoWidth)
                        .subscribe(onError: { [weak self] (error) in
                            guard !AppError.errorByNetworkConnection(error) else { return }
                            self?.clickableDelegate?.errorWhenLoadingMedia(error: error)
                        })
                        .disposed(by: disposeBag)
                }
            }
        }

        photosView.flex.markDirty()
    }

    fileprivate func addMediaView(media: MediaData) -> ImageView {
        let photoImageView = makePhotoImageView()
        if media.mediaSource == .video {
            photosView.flex.define { (flex) in
                flex.addItem().height(20).backgroundColor(.clear)

                flex.addItem().width(photoWidth).height(photoWidth).justifyContent(.center).define { (flex) in
                    flex.addItem(photoImageView).grow(1)
                    flex.addItem(makePlayButton(mediaSourceKey: media.source))
                        .position(.absolute)
                        .alignSelf(.center)
                        .grow(1)
                }
            }
        } else {
            photosView.flex.define { (flex) in
                flex.addItem().height(20).backgroundColor(.clear)
                flex.addItem(photoImageView).width(photoWidth).height(photoWidth)
            }
        }

        return photoImageView
    }
}

extension MediaPostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        clickableDelegate?.click(textView, url: URL)
        return false
    }
}

extension MediaPostTableViewCell {
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

    fileprivate func makePhotoImageView() -> ImageView {
        let imageView = ImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    fileprivate func makePlayButton(mediaSourceKey: String) -> Button {
        let button = Button()
        button.setImage(R.image.playVideo(), for: .normal)
        button.rx.tap.bind { [weak self] in
            self?.clickableDelegate?.playVideo(mediaSourceKey)
        }.disposed(by: disposeBag)
        return button
    }
}
