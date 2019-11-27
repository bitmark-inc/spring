//
//  ServerAssetsService.swift
//  Synergy
//
//  Created by thuyentruong on 11/22/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class ServerAssetsService {

    static var provider = MoyaProvider<ServerAssetsAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getFBAutomation() -> Single<[FBScript]> {
        Global.log.info("[start] getFBAutomation")

        return provider.rx
            .request(.fbAutomation)
            .filterSuccess()
            .map([FBScript].self, atKeyPath: "pages")
    }
}
