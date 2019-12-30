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

    func loadURL(_ url: URL, width: CGFloat) -> Completable {
        return Completable.create { (event) -> Disposable in
            _ = ImageService.makePhotoURL(key: url.path)
                .subscribe(onSuccess: { [weak self] (photoURL, modifier) in
                    guard let self = self else { return }
                    self.kf.setImage(with: photoURL, options: [.requestModifier(modifier)]) { [weak self] (result) in
                        switch result {
                        case .success(_):
                            event(.completed)
                        case .failure(let error):
                            event(.error(error))
                        }
                    }
                }, onError: { (error) in
                    event(.error(error))
                })
            return Disposables.create()
        }
    }

    func setupViews() {
        contentMode = .scaleAspectFit
        layer.masksToBounds = true
    }
}
