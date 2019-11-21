//
//  String+SupportBitmark.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift

extension String {

    func maybeBeatID() -> Bool {
        return count == 128
    }

    func maybeAccountID() -> Bool {
        return count == 50
    }

    func recoveryKey() -> [String] {
        return split(separator: " ").map(String.init).filter { $0.isNotEmpty }
    }
}
