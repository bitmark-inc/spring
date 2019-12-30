//
//  Insight.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Insight: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var sectionName: String = ""
    @objc dynamic var timeUnit: String = ""
    @objc dynamic var startedAt: Date = Date()
    @objc dynamic var quantity: Int = 0
    @objc dynamic var value: Double = 0.0
    @objc dynamic var diffFromPrevious: Double = 0
    @objc dynamic var groups: String?

    override static func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, quantity, value, groups
        case sectionName = "section_name"
        case timeUnit = "period"
        case startedAt = "period_started_at"
        case diffFromPrevious = "diff_from_previous"
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sectionName = try values.decode(String.self, forKey: .sectionName)
        timeUnit = try values.decode(String.self, forKey: .timeUnit)
        let timestampInterval = try values.decode(Double.self, forKey: .startedAt)
        startedAt = Date(timeIntervalSince1970: timestampInterval)
        quantity = try values.decode(Int.self, forKey: .quantity)
        value = try values.decode(Double.self, forKey: .value)
        diffFromPrevious = try values.decode(Double.self, forKey: .diffFromPrevious)

        id = SectionScope(date: startedAt,
                          timeUnit: TimeUnit(rawValue: timeUnit) ?? .week,
                          section: Section(rawValue: sectionName) ?? .post).makeID()

        if let groupsValue = try values.decodeIfPresent(Groups.self, forKey: .groups) {
            groups = try GroupsConverter(from: groupsValue).valueAsString
        }
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
