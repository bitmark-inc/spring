//
//  Auth.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import SwiftDate

struct Auth: Decodable {
    let expireIn: Int
    let jwtToken: String
    let refreshDate: Date = Date()

    enum CodingKeys: String, CodingKey {
        case expireIn = "expire_in"
        case jwtToken = "jwt_token"
    }

    var isValid: Bool {
        return refreshDate.adding(.second, value: expireIn) - 5.minutes >= Date()
    }
}
