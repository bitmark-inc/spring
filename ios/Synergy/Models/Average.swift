//
//  Average.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Average: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var sectionID: Int = 0
    @objc dynamic var timeUnit: String = ""
    @objc dynamic var avg: Double = 0

    override static func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, avg
        case sectionID = "section_id"
        case timeUnit = "time_unit"
    }
}
