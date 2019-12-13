//
//  SettingsBundle.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

class SettingsBundle {
    struct Keys {
        static let appVersionKey = "version_preference"
        static let kVersion = "CFBundleShortVersionString"
        static let kBundle = "CFBundleVersion"
    }

    static func setVersion() {
        let appVersion = Bundle.main.infoDictionary?[SettingsBundle.Keys.kVersion] ?? ""
        let bundleVersion = Bundle.main.infoDictionary?[SettingsBundle.Keys.kBundle] ?? ""

        UserDefaults.standard.appVersion = "\(appVersion) (\(bundleVersion))"
    }
}
