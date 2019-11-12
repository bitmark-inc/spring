//
//  StringProtocol+nsRange.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension StringProtocol {
  func nsRange(from range: Range<Index>) -> NSRange {
    return .init(range, in: self)
  }
}
