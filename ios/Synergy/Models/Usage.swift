//
//  Usage.swift
//  Synergy
//
//  Created by thuyentruong on 11/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

typealias UsageScope = (sectionName: String, timeUnit: String, date: Date)

class Usage: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var sectionName: String = ""
    @objc dynamic var timeUnit: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var quantity: Int = 0
    @objc dynamic var diffFromPrevious: Int = 0
    var groups = List<Group>()

    override static func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, date, quantity, groups
        case sectionName = "section_name"
        case timeUnit = "time_unit"
        case diffFromPrevious = "diff_from_previous"
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sectionName = try values.decode(String.self, forKey: .sectionName)
        timeUnit = try values.decode(String.self, forKey: .timeUnit)
        let timestampInterval = try values.decode(Double.self, forKey: .date)
        date = Date(timeIntervalSince1970: timestampInterval)
        quantity = try values.decode(Int.self, forKey: .quantity)
        diffFromPrevious = try values.decode(Int.self, forKey: .diffFromPrevious)
        groups = try values.decode(List<Group>.self, forKey: .groups)
        id = Usage.makeID((sectionName: sectionName, timeUnit: timeUnit, date: date))
    }

    // MARK: - Realm Required Init
    required init() {
        super.init()
    }

    override init(value: Any) {
        super.init(value: value)
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
}

extension Usage {
    static func makeID(_ usageScope: UsageScope) -> String {
        let (sectionName, timeUnit, date) = usageScope
        let dateTimestamp = Int(date.timeIntervalSince1970)
        return "\(sectionName)_\(timeUnit)_\(dateTimestamp)"
    }
}

enum Section: String {
    case posts
    case reactions
    case message
    case adInterest
    case adveriser
    case location
}

enum TimeUnit: String {
    case week
    case year
    case decade
}
