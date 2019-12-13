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
    var didUserTapNotification: Bool = false

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

    func setupCoreData() -> Completable {
        return Completable.create { (event) -> Disposable in
            guard let currentAccount = Global.current.account else {
                event(.error(AppError.emptyCurrentAccount))
                return Disposables.create()
            }

            do {
                try RealmConfig.setupDBForCurrentAccount()
                try KeychainStore.saveToKeychain(currentAccount.seed.core)
                event(.completed)
            } catch {
                event(.error(error))
            }
            return Disposables.create()
        }
    }

    let networkLoggerPlugin: [PluginType] = [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(output: { (_, items) in
            for item in items {
                Global.log.info(item)
            }
        })),
        MoyaAuthPlugin(tokenClosure: {
            return AuthService.shared.auth?.jwtToken
        })
    ]
}

enum AppError: Error {
    case emptyLocal
    case emptyCurrentAccount
    case emptyJWT
    case emptyFBArchiveCreatedAtInUserDefaults
    case emptyCredentialKeychain
    case incorrectLocal
    case incorrectThread
    case incorrectMetadataLocal
    case missingFileNameFromServer
    case noInternetConnection
    case incorrectPostFilter
    case requireAppUpdate(updateURL: URL)
    case fbArchivePageIsNotReady

    static func errorByNetworkConnection(_ error: Error) -> Bool {
        guard let error = error as? Self else { return false }
        switch error {
        case .noInternetConnection:
            return false
        default:
            return true
        }
    }
}

enum AccountError: Error {
    case invalidRecoveryKey
}

extension UserDefaults {
    var FBArchiveCreatedAt: Date? {
        get { return date(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var enteredBackgroundTime: Date? {
        get { return date(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
    
    var enablePushNotification: Bool {
        get { return bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    // MARK: - Settings
    var appVersion: String? {
        get { return string(forKey: "version_preference") }
        set { set(newValue, forKey: "version_preference") }
    }
}
