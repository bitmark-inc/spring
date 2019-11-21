//
//  Constant.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

public struct Constant {
    static let `default` = Constant()

    public struct InfoKey {
        public static let zeroAddress = "ZERO_ADDRESS"
        public static let stripePublishableKey = "STRIPE_PUBLISHABLE_KEY"
        public static let youtubeClientID = "YOUTUBE_CLIENT_ID"
        public static let intercomAppID = "INTERCOM_APP_ID"
        public static let intercomAppKey = "INTERCOM_APP_KEY"
        public static let appleMerchantID = "APPLE_MERCHANT_ID"
        public static let sentryDSN = "SENTRY_DSN"
    }

    let zeroAccountNumber = Credential.valueForKey(keyName: Constant.InfoKey.zeroAddress)
    let stripePublishableKey = Credential.valueForKey(keyName: Constant.InfoKey.stripePublishableKey)
    let googleAPIClientID = Credential.valueForKey(keyName: Constant.InfoKey.youtubeClientID)
    let intercomAppID = Credential.valueForKey(keyName: Constant.InfoKey.intercomAppID)
    let intercomAppKey = Credential.valueForKey(keyName: Constant.InfoKey.intercomAppKey)
    let appleMerchantID = Credential.valueForKey(keyName: Constant.InfoKey.appleMerchantID)
    let sentryDSN = Credential.valueForKey(keyName: Constant.InfoKey.sentryDSN)
    let oneSignalAppID = Credential.valueForKey(keyName: "ONESIGNAL_APP_ID")

    public static let productLink = "https://apps.apple.com/us/app/bitmark/id1429427796"
    let numberOfPhrases = 12
}
