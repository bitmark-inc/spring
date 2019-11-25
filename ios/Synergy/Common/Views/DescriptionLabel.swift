//
//  DescriptionLabel.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class DescriptionLabel: Label {
    override func setupViews() {
        super.setupViews()

        font = R.font.atlasGroteskRegular(size: Size.ds(18))
        numberOfLines = 0
        textAlignment = .center
    }
}

class LightDesriptionLabel: LightLabel {
    override func setupViews() {
        super.setupViews()

        font = R.font.atlasGroteskRegular(size: Size.ds(18))
        numberOfLines = 0
        textAlignment = .center
    }
}
