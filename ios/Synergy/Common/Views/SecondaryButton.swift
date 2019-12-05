//
//  SecondaryButton.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class SecondaryButton: Button {

    override func setupViews() {
        super.setupViews()

        titleLabel?.font = R.font.atlasGroteskLight(size: Size.ds(14))
        backgroundColor = .clear

        themeService.rx
            .bind({ $0.lightButtonTextColor }, to: rx.titleColor(for: .normal))
            .bind({ $0.lightButtonTextColor.withAlphaComponent(0.5) }, to: rx.titleColor(for: .disabled))
            .disposed(by: disposeBag)

        flex.height(Size.dh(27))
            .right(0).left(0) // full width
    }
}
