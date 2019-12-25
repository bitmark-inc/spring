//
//  InsightService.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class InsightService {

    static var provider = MoyaProvider<InsightAPI>(plugins: Global.default.networkLoggerPlugin)

    static func get(in timeUnit: TimeUnit, startDate: Date) -> Single<[Insight]> {
        Global.log.info("[start] InsightService.get")

        let insightAPI: InsightAPI!
        switch timeUnit {
        case .week:     insightAPI = .getInWeek(startDate: startDate)
        case .year:     insightAPI = .getInYear(startDate: startDate)
        case .decade:   insightAPI = .getInDecade(startDate: startDate)
        }

        return provider.rx.requestWithRefreshJwt(insightAPI)
            .filterSuccess()
            .map([Insight].self, atKeyPath: "result")
    }
}
