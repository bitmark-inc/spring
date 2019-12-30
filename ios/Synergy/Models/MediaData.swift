//
//  MediaData.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//


import Foundation
import Realm
import RealmSwift
import SwiftDate

class MediaData: Object, Decodable {
    @objc dynamic var source: String = ""
    @objc dynamic var thumbnail: String?
    @objc dynamic var type: String = ""

    override class func primaryKey() -> String? {
        return "source"
    }
}

extension MediaData {
    var mediaSource: MediaSource {
        return MediaSource(rawValue: type) ?? .photo
    }
}

enum MediaSource: String {
    case video
    case photo
}
