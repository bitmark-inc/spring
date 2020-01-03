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
            .onlineRequest(.fbAutomation)
            .filterSuccess()
            .map([FBScript].self, atKeyPath: "pages")
    }

    static func getAppInformation() -> Single<(minimumClientVersion: Int?, appUpdateURL: String?)> {
        Global.log.info("[start] getAppInformation")

        return provider.rx
            .onlineRequest(.appInformation)
            .mapJSON()
            .map { ($0 as? [String: Any])?["information"] as? [String: Any] }.errorOnNil()
            .map { $0["ios"] as? [String: Any] }.errorOnNil()
            .map({ (iosInfo) in
                return (minimumClientVersion: iosInfo["minimum_client_version"] as? Int,
                        appUpdateURL: iosInfo["app_update_url"] as? String)
            })
    }
}
