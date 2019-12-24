//
//  UsageService.swift
//  Synergy
//
//  Created by thuyentruong on 11/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class UsageService {

    static var provider = MoyaProvider<UsageAPI>(plugins: Global.default.networkLoggerPlugin)

    static func get(in timeUnit: TimeUnit, startDate: Date) -> Single<[Usage]> {
        Global.log.info("[start] UsageService.get")

        let usageAPI: UsageAPI!
        switch timeUnit {
        case .week: usageAPI = .getInWeek(startDate: startDate)
        case .year: usageAPI = .getInYear(startDate: startDate)
        case .decade: usageAPI = .getInDecade(startDate: startDate)
        }

        return provider.rx.requestWithRefreshJwt(usageAPI)
            .filterSuccess()
            .map([Usage].self, atKeyPath: "result")
    }

    static func getAverage(timeUnit: TimeUnit) -> Single<[Average]> {
        guard let url = Bundle.main.url(forResource: "average_usage", withExtension: "json") else {
            return Single.never()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([Average].self, from: data)
            return Single.just(jsonData)
        } catch {
            return Single.error(error)
        }
    }
}
