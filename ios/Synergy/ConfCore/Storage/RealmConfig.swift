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
        let encryptionKeyData = try getKey()

        switch self {
        case .anonymous:
            fileURL = dbDirectoryURL().appendingPathComponent("data.realm")

        case .user(let accountNumber):
            fileURL = dbDirectoryURL().appendingPathComponent("\(accountNumber).realm")
        }

        return Realm.Configuration(
            fileURL: fileURL,
            encryptionKey: encryptionKeyData,
            schemaVersion: 1
        )
    }

    fileprivate func dbDirectoryURL() -> URL {
        Global.log.debug("[start] dbDirectoryURL")
        let dbDirectory = URL(fileURLWithPath: "db", relativeTo: FileManager.documentDirectoryURL)

        do {
            if KeychainStore.getEncryptedDBKeyFromKeychain() == nil && FileManager.default.fileExists(atPath: dbDirectory.path) {
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
    fileprivate func getKey() throws -> Data {
        guard let encryptedDBKey = KeychainStore.getEncryptedDBKeyFromKeychain() else {
            #if targetEnvironment(simulator)
            let key = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012345678901".data(using: .utf8)!
            #else
            var key = Data(count: 64)
            _ = key.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> Void in
                guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
                _ = SecRandomCopyBytes(kSecRandomDefault, 64, pointer)
            })
            #endif

            try KeychainStore.saveEncryptedDBKeyToKeychain(key)
            return key
        }

        return encryptedDBKey
    }
}
