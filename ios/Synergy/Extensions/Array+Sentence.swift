//
//  Array+Sentence.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension Array where Element == String {
    func toSentence(connector: String = ", ", lastConnector: String = R.string.localizable.and()) -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        default:
            var names = self
            let lastName = names.removeLast()
            return names.joined(separator: connector) + " \(lastConnector) \(lastName)"
        }
    }
}
