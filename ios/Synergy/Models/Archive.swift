//
//  Archive.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Archive: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: Int64 = 0
    @objc dynamic var status: String = ""
    @objc dynamic var contentHash: String = ""
    @objc dynamic var issueBitmark: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case contentHash = "content_hash"
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

enum ArchiveStatus: String {
    case submitted, stored, processed, invalid
}
