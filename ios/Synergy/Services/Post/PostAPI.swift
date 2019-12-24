//
//  PostAPI.swift
//  Synergy
//
//  Created by thuyentruong on 12/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum PostAPI {
    case get(startDate: Date, endDate: Date)
}

extension PostAPI: AuthorizedTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/posts")!
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
