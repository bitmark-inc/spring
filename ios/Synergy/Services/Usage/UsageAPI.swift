//
//  UsageAPI.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/20/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum UsageAPI {
    case getInWeek(startDate: Date)
    case getInYear(startDate: Date)
    case getInDecade(startDate: Date)
}

extension UsageAPI: TargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/usage")!
    }

    var path: String {
        switch self {
        case .getInWeek:
            return "week"
        case .getInYear:
            return "year"
        case .getInDecade:
            return "decade"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var sampleData: Data {
        return Data()
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [:]

        switch self {
        case .getInWeek(let startDate),
             .getInYear(let startDate),
             .getInDecade(let startDate):
            params["started_at"] = startDate.appTimeFormat
        }

        return params
    }

    var task: Task {
        if let parameters = parameters {
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
        return .requestPlain
    }

    var headers: [String: String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
    }
}
