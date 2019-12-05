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

var i = 0

class Post: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var type: String?
    @objc dynamic var post: String?
    @objc dynamic var url: String?
    @objc dynamic var photo: String?
    @objc dynamic var location: Location?
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var friendTags: String = ""
    @objc dynamic var thumbnail: String?

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case id, type, post, url, photo, tags, location, timestamp, friendTags, thumbnail
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        id = "\(id)\(i)"
        i = i + 1
        type = try values.decodeIfPresent(String.self, forKey: .type)
        post = try values.decodeIfPresent(String.self, forKey: .post)?.fbDecode()

        if type == nil, let post = post, post.isNotEmpty {
            type = Constant.PostType.update
        }

        if type == "external" {
            type = Constant.PostType.link
        }

        url = try values.decodeIfPresent(String.self, forKey: .url)
        photo = try values.decodeIfPresent(String.self, forKey: .photo)
        location = try values.decodeIfPresent(Location.self, forKey: .location)
        let timestampInterval = try values.decode(Double.self, forKey: .timestamp)
        timestamp = min(Date(timeIntervalSince1970: timestampInterval), Date())
        thumbnail = try values.decodeIfPresent(String.self, forKey: .thumbnail)

        let tags = try values.decodeIfPresent(List<String>.self, forKey: .tags)?.compactMap { $0.fbDecode() }
        if let tags = tags {
            friendTags = tags.joined(separator: Constant.separator) + Constant.separator
        } else {
            friendTags = ""
        }
    }

    var tags: [String] {
        friendTags.split(separator: String.Element(Constant.separator)).map(String.init)
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

class Location: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var name: String = ""
    @objc dynamic var url: String?
    @objc dynamic var address: String?

    override class func primaryKey() -> String? {
        return "url"
    }

    enum CodingKeys: String, CodingKey {
        case name, url, address
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name).fbDecode()
        url = try values.decodeIfPresent(String.self, forKey: .url)
        address = try values.decodeIfPresent(String.self, forKey: .address)
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

