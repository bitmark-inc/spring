//
//  R.generated + Font.swift
//  Synergy
//
//  Created by thuyentruong on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Rswift

extension R.font {
    static let avenir = Rswift.FontResource(fontName: "Avenir")

    static func avenir(size: CGFloat) -> UIKit.UIFont? {
      return UIKit.UIFont(resource: avenir, size: size)
    }
}
