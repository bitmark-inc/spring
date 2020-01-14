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

        static let accountNumbeKey = "accountNumber_preference"
    }

    static func setVersion() {
        let appVersion = Bundle.main.infoDictionary?[SettingsBundle.Keys.kVersion] ?? ""
        let bundleVersion = Bundle.main.infoDictionary?[SettingsBundle.Keys.kBundle] ?? ""

        UserDefaults.standard.appVersion = "\(appVersion) (\(bundleVersion))"
    }

    static func setAccountNumber(accountNumber: String?) {
        UserDefaults.standard.accountNumber = accountNumber?.middleShorten()
    }

    static func shouldShowReleaseNote() -> Bool {
        guard let currentBundleVersion = Int(Bundle.main.infoDictionary?[SettingsBundle.Keys.kBundle] as? String ?? ""),
            let latestBundleVersion = fetchLatestBundleVersion()
            else {
                return false
        }

        return latestBundleVersion < currentBundleVersion
    }

    static func fetchLatestBundleVersion() -> Int? {
        guard let appVersion = UserDefaults.standard.appVersion else {
            return nil
        }

        let regex = try? NSRegularExpression(pattern: "\\(\\d+", options: [])
        let appVersionRange = NSMakeRange(0, appVersion.count)

        guard let buildVersionRange = regex?.firstMatch(in: appVersion, options: [], range: appVersionRange)?.range,
            let buildVersion = appVersion[safe: buildVersionRange.lowerBound+1..<buildVersionRange.upperBound]
            else {
                return nil
        }

        return Int(buildVersion)
    }
}

extension String {
    func middleShorten(eachMaxChars: Int = 4) -> String {
        let prefixPart = self[safe: 0..<eachMaxChars]!
        let suffixPart = self[safe: count - eachMaxChars..<count]!
        return "[" + prefixPart + "..." + suffixPart + "]"
    }
}
