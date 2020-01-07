//
//  RealmConfig.swift
//  Synergy
//
//  Created by Thuyen Truong on 7/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmConfig {

    static func setupDBForCurrentAccount() throws {
        guard let accountNumber = Global.current.account?.getAccountNumber() else { return }

        _ = try RealmConfig.user(accountNumber).configuration()
    }

    static func currentRealm() throws -> Realm {
        guard let accountNumber = Global.current.account?.getAccountNumber() else {
            throw AppError.emptyCurrentAccount
        }
        let userConfiguration = try RealmConfig.user(accountNumber).configuration()
        Global.log.debug("UserRealm: \(userConfiguration)")
        return try Realm(configuration: userConfiguration)
    }

    static func globalRealm() throws -> Realm {
        let configuration = try RealmConfig.anonymous.configuration()
        Global.log.debug("globalRealm: \(configuration)")
        return try Realm(configuration: configuration)
    }

    case anonymous
    case user(String)

    func configuration() throws -> Realm.Configuration {
        var fileURL: URL!
        let encryptionKeyData: Data!

        switch self {
        case .anonymous:
            fileURL = dbDirectoryURL().appendingPathComponent("data.realm")
            encryptionKeyData = try getKey()

        case .user(let accountNumber):
            fileURL = dbDirectoryURL(for: accountNumber).appendingPathComponent("\(accountNumber).realm")
            encryptionKeyData = try getKey(for: accountNumber)
        }

        return Realm.Configuration(
            fileURL: fileURL,
            encryptionKey: encryptionKeyData,
            schemaVersion: 1
        )
    }

    static func removeRealm(of accountNumber: String) throws {
        guard let realmURL = try Self.user(accountNumber).configuration().fileURL else { return }
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]

        for URL in realmURLs {
            try FileManager.default.removeItem(at: URL)
        }

        try KeychainStore.removeEncryptedDBKeyFromKeychain(for: accountNumber)
    }

    fileprivate func dbDirectoryURL(for accountNumber: String = "") -> URL {
        Global.log.debug("[start] dbDirectoryURL")
        let dbDirectory = FileManager.databaseDirectoryURL

        do {
            if KeychainStore.getEncryptedDBKeyFromKeychain(for: accountNumber) == nil && FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.removeItem(at: dbDirectory)
            }

            if !FileManager.default.fileExists(atPath: dbDirectory.path) {
                try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
                try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: dbDirectory.path)
            }
        } catch {
            Global.log.error(error)
        }

        Global.log.debug("[done] dbDirectoryURL")
        return dbDirectory
    }

    // Reference: https://realm.io/docs/swift/latest/#encryption
    fileprivate func getKey(for accountNumber: String = "") throws -> Data {
        guard let encryptedDBKey = KeychainStore.getEncryptedDBKeyFromKeychain(for: accountNumber) else {
            #if targetEnvironment(simulator)
            let key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012345678901".data(using: .utf8)!
            #else
            var key = Data(count: 64)
            _ = key.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> Void in
                guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
                _ = SecRandomCopyBytes(kSecRandomDefault, 64, pointer)
            })
            #endif

            try KeychainStore.saveEncryptedDBKeyToKeychain(key, for: accountNumber)
            return key
        }

        return encryptedDBKey
    }
}
