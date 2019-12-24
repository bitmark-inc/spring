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

class Usage: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var sectionName: String = ""
    @objc dynamic var timeUnit: String = ""
    @objc dynamic var startedAt: Date = Date()
    @objc dynamic var quantity: Int = 0
    @objc dynamic var diffFromPrevious: Double = 0
    @objc dynamic var groups: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, quantity, groups
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
        diffFromPrevious = try values.decode(Double.self, forKey: .diffFromPrevious)

        id = Usage.makeID(usageScope: UsageScope(
            date: startedAt,
            timeUnit: TimeUnit(rawValue: timeUnit) ?? .week,
            section: Section(rawValue: sectionName) ?? .posts))

        let groupsValue = try values.decode(Groups.self, forKey: .groups)
        groups = try GroupsConverter(from: groupsValue).valueAsString
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
    static func makeID(usageScope: UsageScope) -> String {
        let sectionName = usageScope.section.rawValue
        let timeUnit = usageScope.timeUnit.rawValue
        let dateTimestamp = usageScope.date.appTimeFormat
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

    func barDateComponents(distance: Int) -> DateComponents {
        switch self {
        case .week: return DateComponents(day: distance)
        case .year: return DateComponents(month: distance)
        case .decade: return DateComponents(year: distance)
        }
    }

    func shortenDayName(for date: Date) -> String {
        switch self {
        case .week: return date.dayName(ofStyle: .oneLetter)
        case .year: return date.monthName(ofStyle: .oneLetter)
        case .decade: return date.toFormat("yy")
        }
    }
}
