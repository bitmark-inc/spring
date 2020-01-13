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
    @objc dynamic var key: String = ""
    @objc dynamic var value: String = ""

    override class func primaryKey() -> String? {
        return "key"
    }

    convenience init<T: Codable>(key: UserInfoKey, value: T) throws {
        self.init()
        self.key = key.rawValue
        self.value = try Converter<T>(from: value).valueAsString
    }
}

extension UserInfo {
    func valueObject<T: Codable>() -> T? {
        do {
            return try Converter<T>(from: value).value
        } catch {
            Global.log.error(error)
            return nil
        }
    }
}

enum UserInfoKey: String {
    case adsCategory
    case insight
}
