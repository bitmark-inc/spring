//
//  Global.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import BitmarkSDK
import Moya

class Global {
    static var current = Global()
    static let `default` = current

    var account: Account?
    var currency: Currency?

    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        //    let dateFormat = ISO8601DateFormatter()
        let dateFormat = DateFormatter()
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat.dateFormat = "yyyy-MM-dd'T'H:m:ss.SSSS'Z"

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            guard let date = dateFormat.date(from: dateString) else {
                throw "cannot decode date string \(dateString)"
            }
            return date
        })
        return decoder
    }()

    let networkLoggerPlugin: [PluginType] = [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(output: { (_, items) in
            for item in items {
                Global.log.info(item)
            }
        }))
    ]
}

enum FlowError: Error {
    case emptyLocal
    case emptyCurrentAccount
    case emptyJWT
    case incorrectLocal
    case incorrectThread
    case incorrectMetadataLocal
    case missingFileNameFromServer
    case noInternetConnection

    static func errorByNetworkConnection(_ error: Error) -> Bool {
        guard let error = error as? Self, error == .noInternetConnection else { return false }
        return true
    }
}

enum AccountError: Error {
    case invalidRecoveryKey
}
