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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override func setupViews() {
        super.setupViews()
        font = Avenir.size(24)
        numberOfLines = 0
        textAlignment = .center
    }
}

class BeatTitleLabel: Label {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override func setupViews() {
        super.setupViews()
        font = Avenir.Heavy.size(22)
        numberOfLines = 0
    }
}
