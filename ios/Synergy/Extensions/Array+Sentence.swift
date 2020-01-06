//
//  Array+Sentence.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension Array where Element == String {
    func toFriendsSentence(connector: String = ", ", twoConnection: String = " & ", lastConnector: String = R.string.localizable.and()) -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        case 2:
            return self.joined(separator: twoConnection)
        case 3:
            var names = self
            let lastName = names.removeLast()
            return names.joined(separator: connector) + " \(lastConnector) \(lastName)"
        default:
            return R.string.localizable.friendsWithOther(
                self[0..<2].joined(separator: connector),
                String(self.count - 2))
        }
    }
}
