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
    fileprivate static let accountCoreKey = "account_core"
    fileprivate static func makeEncryptedDBKey(number: String) -> String {
        "synergy_encrypted_db_key_\(number)"
    }
    fileprivate static let fbCredentialUsernameKey = "fb_credential_username_key"
    fileprivate static let fbCredentialPasswordKey = "fb_credential_password_key"

    fileprivate static let keychain: Keychain = {
        return Keychain(service: Bundle.main.bundleIdentifier!)
            .authenticationPrompt(R.string.localizable.yourAuthorizationIsRequired())
    }()

    // MARK: - Handlers
    // *** seed Core ***
    static func saveToKeychain(_ seedCore: Data, isSecured: Bool) throws {
        Global.log.info("[start] saveToKeychain")
        defer { Global.log.info("[done] saveToKeychain") }

        try removeSeedCoreFromKeychain()

        if isSecured {
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .set(seedCore, key: accountCoreKey)
        } else {
            try keychain.set(seedCore, key: accountCoreKey)
        }
        Global.current.userDefault?.isAccountSecured = isSecured
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
    static func saveEncryptedDBKeyToKeychain(_ encryptedKey: Data, for accountNumber: String) throws {
        Global.log.info("save EncryptedDBKey into keychain")
        defer { Global.log.info("finished saving EncryptedDBKey into keychain") }

        let encryptedDBKey = makeEncryptedDBKey(number: accountNumber)

        try keychain.accessibility(Accessibility.afterFirstUnlock)
            .set(encryptedKey, key: encryptedDBKey)
    }

    static func getEncryptedDBKeyFromKeychain(for accountNumber: String) -> Data? {
        do {
            let encryptedDBKey = makeEncryptedDBKey(number: accountNumber)
            return try keychain.getData(encryptedDBKey)
        } catch {
            return nil
        }
    }
    
    static func removeEncryptedDBKeyFromKeychain(for accountNumber: String) throws {
        Global.log.info("[start] removeEncryptedDBKeyFromKeychain")
        defer { Global.log.info("[done] removeEncryptedDBKeyFromKeychain") }
        
        let encryptedDBKey = makeEncryptedDBKey(number: accountNumber)
        try keychain.remove(encryptedDBKey)
    }

    // *** FB Credential ***
    static func saveFBCredentialToKeychain(_ username: String, password: String) throws {
        Global.log.info("[start] saveFBCredentialToKeychain")

        try keychain.remove(fbCredentialUsernameKey)
        try keychain.remove(fbCredentialPasswordKey)

        try keychain
            .accessibility(.whenUnlocked)
            .set(username, key: fbCredentialUsernameKey)
        try keychain
            .accessibility(.whenUnlocked)
            .set(password, key: fbCredentialPasswordKey)
    }

    static func getFBCredentialToKeychain() -> Single<(username: String, password: String)> {
        Global.log.info("[start] getFBCredentialToKeychain")

        return Single.create(subscribe: { (single) -> Disposable in
            DispatchQueue.global().async {
                do {
                    guard let username = try keychain.get(fbCredentialUsernameKey),
                        let password = try keychain.get(fbCredentialPasswordKey) else {
                            Global.log.error(AppError.emptyCredentialKeychain)
                            return
                    }

                    Global.log.info("[done] getFBCredentialToKeychain")
                    single(.success((username: username, password: password)))
                } catch {
                    single(.error(error))
                }
            }
            return Disposables.create()
        })
    }

    static func getFBUsername() -> Single<String> {
        Global.log.info("[start] getFBUsername")

        return Single.create(subscribe: { (single) -> Disposable in
            DispatchQueue.global().async {
                do {
                    guard let username = try keychain.get(fbCredentialUsernameKey)
                        else {
                            Global.log.error(AppError.emptyCredentialKeychain)
                            return
                    }

                    Global.log.info("[done] getFBUsername")
                    single(.success(username))
                } catch {
                    single(.error(error))
                }
            }
            return Disposables.create()
        })
    }

    static func removeFBCredential() throws {
        Global.log.info("[start] removeFBCredential")
        defer { Global.log.info("[done] removeFBCredential") }

        try keychain.remove(fbCredentialUsernameKey)
        try keychain.remove(fbCredentialPasswordKey)
    }
}
