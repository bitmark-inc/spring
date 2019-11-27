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
        Global.log.info("[start] FbmAccountService.create")

        return provider.rx
            .requestWithRefreshJwt(.create)
            .filterSuccess()
            .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder)
    }

    static func getMe() -> Single<FbmAccount> {
        Global.log.info("[start] FbmAccountService.getMe")

        return provider.rx
            .requestWithRefreshJwt(.getMe)
            .filterSuccess()
            .map(FbmAccount.self, atKeyPath: "result", using: Global.default.decoder )
    }
}
