//
//  FileManager+Directory.swift
//  Synergy
//
//  Created by Thuyen Truong on 6/16/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension FileManager {
    static var documentDirectoryURL: URL {
        return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var databaseDirectoryURL: URL {
      return URL(fileURLWithPath: "db", relativeTo: FileManager.documentDirectoryURL)
    }

    static var filesDocumentDirectoryURL: URL {
        let filesDirectory = URL(fileURLWithPath: "files", relativeTo: documentDirectoryURL)

        do {
            if !FileManager.default.fileExists(atPath: filesDirectory.path) {
                try FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: filesDirectory.path)
            }
        } catch {
            Global.log.error(error)
        }

        return filesDirectory
    }

    static var sharedDirectoryURL: URL? {
        guard let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else { return nil }
        return `default`.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
}
