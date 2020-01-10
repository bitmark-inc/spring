//
//  Metadata.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

class MetadataConverter {

    // MARK: - Properties
    var valueAsString: String!
    var value: Metadata
    let encodingRule: String.Encoding = .utf8

    // MARK: - Init
    init(from value: String) throws {
        valueAsString = value
        guard let jsonData = valueAsString.data(using: encodingRule)
            else {
                throw "invalid metadata string"
        }

        self.value = try JSONDecoder().decode(Metadata.self, from: jsonData)
    }

    init(from value: Metadata) throws {
        self.value = value
        let jsonData = try JSONEncoder().encode(value)
        valueAsString = String(data: jsonData, encoding: encodingRule)
    }
}

struct Metadata: Codable {
    var fbIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case fbIdentifier = "fb-identifier"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fbIdentifier = try values.decodeIfPresent(String.self, forKey: .fbIdentifier)
    }
}
