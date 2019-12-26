//
//  ReactionService.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import Moya

class ReactionService {

    static var provider = MoyaProvider<ReactionAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getAll(startDate: Date, endDate: Date) -> Single<[Reaction]> {
        Global.log.info("[start] ReactionService.get(startDate, endDate)")


        return provider.rx.requestWithRefreshJwt(.get(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map([Reaction].self, atKeyPath: "result")
    }
}
