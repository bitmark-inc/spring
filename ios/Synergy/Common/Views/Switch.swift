//
//  Switch.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class Switch: UISwitch {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else { return }
        snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(17)
        }
    }

    func setupView() {
        transform = CGAffineTransform(scaleX: 1.5, y: 1.3)
    }
}

class SwitchTitleLabel: Label {
    override func setupViews() {
        super.setupViews()

        font = Avenir.Heavy.size(24)
        numberOfLines = 0
    }
}
