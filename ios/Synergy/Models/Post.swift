//
//  Post.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Post: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var type: String = ""
    @objc dynamic var caption: String = ""
    @objc dynamic var url: String?
    @objc dynamic var photo: String?
    @objc dynamic var location: String = ""
    @objc dynamic var timestamp: Date = Date()
    var tags = List<String>()

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, type, caption, url, photo, tags, location, timestamp
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        caption = try values.decode(String.self, forKey: .caption)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        photo = try values.decodeIfPresent(String.self, forKey: .photo)
        location = try values.decode(String.self, forKey: .location)
        let timestampInterval = try values.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampInterval)
        tags = try values.decode(List<String>.self, forKey: .tags)
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
