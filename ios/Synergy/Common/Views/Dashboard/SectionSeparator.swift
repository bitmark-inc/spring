//
//  SectionSeparator.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class SectionSeparator: UIView {

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
