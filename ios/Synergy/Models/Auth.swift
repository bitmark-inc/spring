//
//  Auth.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct Auth: Decodable {
    let expireIn: Date
    let jwtToken: String

    enum CodingKeys: String, CodingKey {
        case expireIn = "expire_in"
        case jwtToken = "jwt_token"
    }
}
