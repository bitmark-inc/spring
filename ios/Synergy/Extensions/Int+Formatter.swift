//
//  Int+Formatter.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/7/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

extension Int {
    var commaRepresentation: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
