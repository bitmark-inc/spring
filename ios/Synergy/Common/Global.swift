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
    static let backgroundErrorSubject = PublishSubject<Error>()

    var account: Account?
    var currency: Currency?
    lazy var userDefault: UserDefaults? = {
        guard let accountNumber = account?.getAccountNumber()
            else { return nil }
        return UserDefaults.userStandard(for: accountNumber)
    }()
    var didUserTapNotification: Bool = false
    static let userInsightID = UserInfoKey.insights.rawValue

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
                try KeychainStore.saveToKeychain(currentAccount.seed.core, isSecured: false)
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
        }),
        MoyaVersionPlugin()
    ]
}

enum AppError: Error {
    case emptyLocal
    case emptyCurrentAccount
    case emptyUserDefaults
    case emptyJWT
    case emptyFBArchiveCreatedAtInUserDefaults
    case emptyCredentialKeychain
    case incorrectLocal
    case incorrectThread
    case incorrectMetadataLocal
    case missingFileNameFromServer
    case noInternetConnection
    case incorrectPostFilter
    case incorrectReactionFilter
    case requireAppUpdate(updateURL: URL)
    case fbRequiredPageIsNotReady
    case loginFailedIsNotDetected
    case incorrectEmptyRealmObject
    case biometricNotConfigured
    case biometricError
    case didRemoteQuery

    static func errorByNetworkConnection(_ error: Error) -> Bool {
        guard let error = error as? Self else { return false }
        switch error {
        case .noInternetConnection:
            return true
        default:
            return false
        }
    }
}

enum AccountError: Error {
    case invalidRecoveryKey
}

extension UserDefaults {
    static func userStandard(for number: String) -> UserDefaults? {
        return UserDefaults(suiteName: number)
    }

    var FBArchiveCreatedAt: Date? {
        get { return date(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var enteredBackgroundTime: Date? {
        get { return date(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var fbCategoriesInfo: [Any]? {
        get { return array(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    // MARK: - Settings
    var appVersion: String? {
        get { return string(forKey: "version_preference") }
        set { set(newValue, forKey: "version_preference") }
    }

    var accountNumber: String? {
        get { return string(forKey: "accountNumber_preference") }
        set { set(newValue, forKey: "accountNumber_preference") }
    }

    var enablePushNotification: Bool {
        get { return bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    // Per Account
    var latestArchiveStatus: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var isAccountSecured: Bool {
        get { return bool(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
}
