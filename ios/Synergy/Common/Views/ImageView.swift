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

    func loadURL(_ url: URL) -> Completable {
        return Completable.create { (event) -> Disposable in
            var photoImageURL = URL(string: Constant.fbImageServerURL)
            photoImageURL?.appendQueryParameters(["key": url.path.urlEncoded])

            self.kf.setImage(with: photoImageURL) { [weak self] (_) in
                guard let self = self, let imageSize = self.image?.size else { return }
                let heightImage = self.frame.size.width * imageSize.height / imageSize.width
                self.flex.maxWidth(100%).height(heightImage)
                event(.completed)
            }

            return Disposables.create()
        }

    }

    func setupViews() {
        contentMode = .scaleAspectFit
        layer.masksToBounds = true
    }
}
