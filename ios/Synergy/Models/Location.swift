//
//  Location.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftDate

class Location: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var url: String?
    @objc dynamic var address: String?
    @objc dynamic var coordinate: String?
    @objc dynamic var createdAt: Date = Date()

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, address, coordinate
        case createdAt = "created_at"
        case name, url
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = String(Date().timeIntervalSince1970)
        name = try values.decode(String.self, forKey: .name)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        coordinate = try values.decodeIfPresent(Coordinate.self, forKey: .coordinate)?.valueAsString()
        let timestampInterval = try values.decode(Double.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: timestampInterval)
    }

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

struct Coordinate: Codable {
    let latitude, longitude: Double

    init(from str: String) throws {
        guard let jsonData = str.data(using: .utf8)
            else {
                throw "invalid coordinate string"
        }
        self = try JSONDecoder().decode(Coordinate.self, from: jsonData)
    }

    func valueAsString() throws -> String? {
        let jsonData = try JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)
    }
}
