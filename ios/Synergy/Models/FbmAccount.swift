//
//  FbmAccount.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class FbmAccount: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var accountNumber: String = ""
    @objc dynamic var metadata: String = ""
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()

    override static func primaryKey() -> String? {
        return "accountNumber"
    }

    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accountNumber = try values.decode(String.self, forKey: .accountNumber)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)

        let metadataValue = try values.decode(Metadata.self, forKey: .metadata)
        metadata = try MetadataConverter(from: metadataValue).valueAsString
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
