//
//  FBArchiveAPI.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum FBArchiveAPI {
    case submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date)
    case getAll
}

extension FBArchiveAPI: AuthorizedTargetType, VersionTargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/archives")!
    }

    var path: String {
        return ""
    }

    var method: Moya.Method {
        switch self {
        case .submit:
            return .post
        case .getAll:
            return .get
        }
    }

    var sampleData: Data {
        return Data()
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [:]
        switch self {
        case .submit(let headers, let fileURL, let rawCookie, let startedAt, let endedAt):
            params["headers"] = headers
            params["file_url"] = fileURL
            params["raw_cookie"] = rawCookie
            params["started_at"] = Int(startedAt?.timeIntervalSince1970 ?? 0)
            params["ended_at"] = Int(endedAt.timeIntervalSince1970)
        case .getAll:
            return nil
        }
        return params
    }

    var task: Task {
        if let parameters = parameters {
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
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
