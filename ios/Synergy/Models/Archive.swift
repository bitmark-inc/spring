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

class Archive: Decodable {
    let id: Int
    let startedAt, endedAt: String
    let status, createdAt, updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum ArchiveStatus: String {
    case submitted, stored, processed, invalid
}
