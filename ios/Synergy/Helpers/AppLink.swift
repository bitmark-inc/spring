//
//  AppLink.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation

enum AppLink: String {
    case termsOfService = "legal-terms"
    case privacyOfPolicy = "legal-privacy"
    case support
    case viewRecoveryKey = "view-recovery-key"

    var path: String {
        return Constant.appName + "://\(rawValue)"
    }

    var generalText: String {
        switch self {
        case .termsOfService:
            return R.string.phrase.termsOfService()
        case .privacyOfPolicy:
            return R.string.phrase.privacyPolicy()
        default:
            return ""
        }
    }

    var websiteURL: URL? {
        switch self {
        case .termsOfService:
            return URL(string: "https://bitmark.com")
        case .privacyOfPolicy:
            return URL(string: "https://bitmark.com/blog-post")
        default:
            return nil
        }
    }
}
