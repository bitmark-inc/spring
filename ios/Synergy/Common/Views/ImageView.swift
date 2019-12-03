//
//  ImageView.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout
import Kingfisher

class ImageView: UIImageView {

    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    override init(image: UIImage?) {
        super.init(image: image)
        setupViews()
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func loadURL(_ url: URL) {
        kf.setImage(with: url)

        guard let imageSize = image?.size else { return }
        let heightImage = frame.size.width * imageSize.height / imageSize.width
        flex.maxWidth(100%).height(heightImage)
    }

    func setupViews() {
        contentMode = .scaleAspectFit
        layer.masksToBounds = true
    }
}
