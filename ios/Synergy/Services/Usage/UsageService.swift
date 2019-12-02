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

    static func get(_ usageScope: UsageScope) -> Single<Usage> {
        Global.log.info("[start] UsageService.get")

        let mockFileName: String!
        guard let section = Section(rawValue: usageScope.sectionID) else { return Single.never() }

        switch section {
        case .posts:
            mockFileName = "post_insights"
        case .reactions:
            mockFileName = "reaction_insights"
        default:
            mockFileName = ""
        }

        guard let url = Bundle.main.url(forResource: mockFileName, withExtension: "json") else {
            return Single.never()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(Usage.self, from: data)
            return Single.just(jsonData)
        } catch {
            return Single.error(error)
        }
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
