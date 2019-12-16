//
//  FbmAccountService.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class FbmAccountService {
    static var provider = MoyaProvider<FbmAccountAPI>(plugins: Global.default.networkLoggerPlugin)

    static func create() -> Single<FbmAccount> {
        return Single.deferred {
            guard let currentAccount = Global.current.account else {
                Global.log.error(AppError.emptyCurrentAccount)
                return Single.never()
            }

            Global.log.info("[start] FbmAccountService.create")
            let encryptedPublicKey = currentAccount.encryptionKey.publicKey.hexEncodedString

            return provider.rx
                .requestWithRefreshJwt(.create(encryptedPublicKey: encryptedPublicKey))
                .filterSuccess()
                .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder)
        }
    }

    static func getMe() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountService.getMe")

        return provider.rx
            .requestWithRefreshJwt(.getMe)
            .filterSuccess()
            .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder )
    }
}
