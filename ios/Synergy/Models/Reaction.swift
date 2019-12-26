//
//  Reaction.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftDate

class Reaction: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var reactionID: Int = 0
    @objc dynamic var reaction: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var timestamp: Date = Date()

    override class func primaryKey() -> String? {
        return "reactionID"
    }

    override class func indexedProperties() -> [String] {
        return ["reaction"]
    }

    enum CodingKeys: String, CodingKey {
        case reactionID = "reaction_id"
        case reaction, title, timestamp
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        reactionID = try values.decode(Int.self, forKey: .reactionID)
        reaction = try values.decode(String.self, forKey: .reaction)
        title = try values.decode(String.self, forKey: .title)

        let timestampInterval = try values.decode(Double.self, forKey: .timestamp)
        timestamp = min(Date(timeIntervalSince1970: timestampInterval), Date())
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

extension Reaction {
    var reactionType: ReactionType? {
        return ReactionType(rawValue: reaction)
    }
}
