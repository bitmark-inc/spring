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

        titleLabel?.font = R.font.atlasGroteskRegular(size: Size.ds(14))
        backgroundColor = .clear

        flex.height(Size.dh(27))
            .right(0).left(0) // full width
    }
}
