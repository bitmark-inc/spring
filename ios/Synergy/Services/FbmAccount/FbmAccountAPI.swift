//
//  FbmAccountAPI.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import Moya

enum FbmAccountAPI {
    case create(encryptedPublicKey: String)
    case getMe
}

extension FbmAccountAPI: AuthorizedTargetType {

    var baseURL: URL {
        return URL(string: Constant.default.fBMServerURL + "/api/accounts")!
    }

    var path: String {
        switch self {
        case .create:
            return ""
        case .getMe:
            return "me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .create:
            return .post
        case .getMe:
            return .get
        }
    }

    var sampleData: Data {
        return Data()
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [:]
        switch self {
        case .create(let encryptedPublicKey):
            params["enc_pub_key"] = encryptedPublicKey
        case .getMe:
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
