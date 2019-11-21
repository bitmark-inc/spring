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

    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func makeHighlightBackground() {
        themeService.rx
            .bind({ $0.highlightTextBackgroundColor }, to: rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    func setupViews() {
        themeService.rx
            .bind({ $0.textColor }, to: rx.textColor)
            .disposed(by: disposeBag)
    }
}
