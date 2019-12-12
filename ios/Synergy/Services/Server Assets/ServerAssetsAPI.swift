//
//  ServerAssetsAPI.swift
//  Synergy
//
//  Created by thuyentruong on 11/22/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Moya

enum ServerAssetsAPI {
    case fbAutomation
    case appInformation
}

extension ServerAssetsAPI: TargetType {
    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL)!
    }

    var path: String {
        switch self {
        case .fbAutomation:
            return "assets/fb_automation.json"
        case .appInformation:
            return "api/information"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fbAutomation, .appInformation:
            return .get
        }
    }

    var sampleData: Data {
        return Data()
    }

    var parameters: [String: Any]? {
        return nil
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
