//
//  String+Extension.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import CryptoKit

extension String {
    func sha3() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        return data.sha3(length: 256).hexEncodedString
    }
}
