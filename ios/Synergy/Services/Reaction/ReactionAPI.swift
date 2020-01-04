//
//  ReactionAPI.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum ReactionAPI {
    case get(startDate: Date, endDate: Date)
}

extension ReactionAPI: AuthorizedTargetType, VersionTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/reactions")!
    }

    var path: String {
        return ""
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
        case .get(let startDate, let endDate):
            params["started_at"] = startDate.appTimeFormat
            params["ended_at"] = endDate.appTimeFormat
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
