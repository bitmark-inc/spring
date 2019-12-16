//
//  Account+Rx.swift
//  Synergy
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import BitmarkSDK
import RxSwift
import Intercom

class AccountService {
    static func registerIntercom(for accountNumber: String?, metadata: [String: String] = [:]) {
        Global.log.info("[start] registerIntercom")
        
        Intercom.logout()
        
        if let accountNumber = accountNumber {
            let intercomUserID = accountNumber.hexDecodedData.sha3(length: 256).hexEncodedString
            Intercom.registerUser(withUserId: intercomUserID)
        } else {
            Intercom.registerUnidentifiedUser()
        }
        
        let userAttributes = ICMUserAttributes()
        
        var metadata = metadata
        metadata["Service"] = (Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String) ?? ""
        userAttributes.customAttributes = metadata
        
        Intercom.updateUser(userAttributes)
        Global.log.info("[done] registerIntercom")
    }
}

extension AccountService: ReactiveCompatible {}

extension Reactive where Base: AccountService {

    static func createNewAccount() -> Single<Account> {
        Global.log.info("[start] createNewAccount")
        return Single.just(()).map { try Account() }
    }

    static func existsCurrentAccount() -> Single<Account?> {
        Global.log.info("[start] existsCurrentAccount")

        return KeychainStore.getSeedDataFromKeychain()
            .flatMap({ (seedCore) -> Single<Account?> in
                guard let seedCore = seedCore else { return Single.just(nil) }
                do {
                    let seed = try Seed.fromCore(seedCore, version: .v2)
                    return Single.just(try Account(seed: seed))
                } catch {
                    Global.log.error(error)
                }
                return Single.just(nil)
            })
    }

    static func getAccount(phrases: [String]) -> Single<Account> {
        do {
            let account = try Account(recoverPhrase: phrases, language: .english)
            return Single.just(account)
        } catch {
            return Single.error(error)
        }
    }
}
