//
//  String+Helper.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }

    func asLink(withLink link: String = "") -> NSAttributedString {
        return NSAttributedString(
            string: self,
            attributes: [.underlineColor: UIColor.Material.white, .underlineStyle: NSUnderlineStyle.single.rawValue, .font: Avenir.size(18), .foregroundColor: UIColor.Material.white]
        )
    }
}
