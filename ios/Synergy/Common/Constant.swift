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

    public struct NotificationIdentifier {
        public static let checkFBArchive = "checkFBArchiveIdentifier"
    }

    // MARK: - Info Credential
    let zeroAccountNumber = Credential.valueForKey(keyName: "ZERO_ADDRESS")
    let stripePublishableKey = Credential.valueForKey(keyName: "STRIPE_PUBLISHABLE_KEY")
    let googleAPIClientID = Credential.valueForKey(keyName: "YOUTUBE_CLIENT_ID")
    let intercomAppID = Credential.valueForKey(keyName: "INTERCOM_APP_ID")
    let intercomAppKey = Credential.valueForKey(keyName: "INTERCOM_APP_KEY")
    let appleMerchantID = Credential.valueForKey(keyName: "APPLE_MERCHANT_ID")
    let sentryDSN = Credential.valueForKey(keyName: "SENTRY_DSN")
    let oneSignalAppID = Credential.valueForKey(keyName: "ONESIGNAL_APP_ID")
    let fBMServerURL = Credential.valueForKey(keyName: "API_FBM_SERVER_URL")

    static let appName = "Synergy"
    public static let productLink = "https://apps.apple.com/us/app/bitmark/id1429427796"
    let numberOfPhrases = 12
    static let postTimestampFormat = "MMM d 'at' h:mm a"

    public struct OneSignalTag {
        public static let key = "account_id"
    }

    public struct PostType {
        public static let update = "update"
        public static let photo = "photo"
        public static let story = "story"
        public static let video = "video"
        public static let link = "link"
    }

    static let separator = ","
}
