//
//  ActivityIndicator.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class ActivityIndicator: UIActivityIndicatorView {

    let disposeBag = DisposeBag()

    init() {
        super.init(frame: CGRect.zero)
        setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            style = .whiteLarge
        }

        themeService.rx
            .bind({ $0.indicatorColor }, to: rx.tintColor)
            .disposed(by: disposeBag)
    }
}
