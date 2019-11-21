//
//  KeychainStore.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import KeychainAccess
import RxSwift

class KeychainStore {

    // MARK: - Properties
    static private let accountCoreKey = "account_core"
    private static let encryptedDBKey = "synergy_encrypted_db_key"

    private static let keychain: Keychain = {
        return Keychain(service: Bundle.main.bundleIdentifier!)
    }()

    // MARK: - Handlers
    // *** seed Core ***
    static func saveToKeychain(_ seedCore: Data) throws {
        Global.log.info("[start] saveToKeychain")
        defer { Global.log.info("[done] saveToKeychain") }

        try removeSeedCoreFromKeychain()
        try keychain.set(seedCore, key: accountCoreKey)
        Global.log.info()
    }

    static func removeSeedCoreFromKeychain() throws {
        Global.log.info("[start] removeSeedCoreFromKeychain")
        defer { Global.log.info("[done] removeSeedCoreFromKeychain") }

        try keychain.remove(accountCoreKey)
    }

    static func getSeedDataFromKeychain() -> Single<Data?> {
        Global.log.info("[start] getSeedDataFromKeychain")

        return Single<Data?>.create(subscribe: { (single) -> Disposable in
            DispatchQueue.global().async {
                do {
                    let seedData = try keychain.getData(accountCoreKey)
                    Global.log.info("[done] getSeedDataFromKeychain")
                    single(.success(seedData))
                } catch {
                    single(.error(error))
                }
            }
            return Disposables.create()
        })
    }

    // *** Encrypted db key ***
    static func saveEncryptedDBKeyToKeychain(_ encryptedKey: Data) throws {
        Global.log.info("save EncryptedDBKey into keychain")
        defer { Global.log.info("finished saving EncryptedDBKey into keychain") }

        try keychain.accessibility(Accessibility.afterFirstUnlock)
            .set(encryptedKey, key: encryptedDBKey)
    }

    static func getEncryptedDBKeyFromKeychain() -> Data? {
        do {
            return try keychain.getData(encryptedDBKey)
        } catch {
            return nil
        }
    }
}
