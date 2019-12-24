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
import SwiftDate

class Post: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: Int = 0
    @objc dynamic var type: String = ""
    @objc dynamic var post: String?
    @objc dynamic var title: String?
    @objc dynamic var url: String?
    @objc dynamic var location: Location?
    @objc dynamic var timestamp: Date = Date()

    let mediaData = List<MediaData>()
    let tags = List<Friend>()

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func indexedProperties() -> [String] {
        return ["type"]
    }

    enum CodingKeys: String, CodingKey {
        case id, type, post, url, location, timestamp, tags, title, mediaData
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String?.self, forKey: .title)
        post = try values.decodeIfPresent(String.self, forKey: .post)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        location = try values.decodeIfPresent(Location.self, forKey: .location)
        location?.id = "postLocation_\(id)"

        let timestampInterval = try values.decode(Double.self, forKey: .timestamp)
        timestamp = min(Date(timeIntervalSince1970: timestampInterval), Date())

        if let friends = try values.decodeIfPresent([String].self, forKey: .tags) {
            tags.append(objectsIn: friends.map({ Friend(name: $0) }))
        }

        if let mediaDataArray = try values.decodeIfPresent([MediaData].self, forKey: .mediaData) {
            mediaData.append(objectsIn: mediaDataArray)
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

class Friend: Object, Decodable {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""

    override class func primaryKey() -> String? {
        return "id"
    }

    convenience init(name: String) {
        self.init()
        self.id = name
        self.name = name
    }
}
