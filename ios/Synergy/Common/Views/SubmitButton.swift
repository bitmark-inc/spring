//
//  SubmitButton.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout

class SubmitButton: Button {
    override func setupViews() {
        super.setupViews()

        titleLabel?.font = R.font.atlasGroteskLight(size: Size.ds(18))

        themeService.rx
            .bind({ UIImage(color: $0.themeColor, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .normal))
            .bind({ UIImage(color: $0.themeColor.withAlphaComponent(0.5), size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .disabled))
            .bind({ $0.lightButtonTextColor }, to: rx.titleColor(for: .normal))
            .bind({ $0.lightButtonTextColor.withAlphaComponent(0.5) }, to: rx.titleColor(for: .disabled))
            .disposed(by: disposeBag)

        flex.height(Size.dh(50))
    }
}
