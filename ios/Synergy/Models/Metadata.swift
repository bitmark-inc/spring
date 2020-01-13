//
//  Metadata.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

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
