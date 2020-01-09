//
//  UserInfo.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/8/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class UserInfo: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var id: String = ""
    @objc dynamic var key: String = ""
    @objc dynamic var value: String = ""

    override class func primaryKey() -> String? {
        return "id"
    }

    convenience init(id: String = NSUUID().uuidString, key: UserInfoKey, value: String) {
        self.init()
        self.id = id
        self.key = key.rawValue
        self.value = value
    }
}

enum UserInfoKey: String {
    case adsCategory
    case insights
}
