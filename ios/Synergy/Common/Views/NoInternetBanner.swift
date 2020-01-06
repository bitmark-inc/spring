//
//  NoInternetBanner.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import NotificationBannerSwift

class NoInternetBanner {

    static let banner: StatusBarNotificationBanner = {
        let banner = StatusBarNotificationBanner(
            title: R.string.error.noInternetConnection(),
            style: .danger,
            colors: CustomBannerColors()
        )
        return banner
    }()

    static func show() {
        _ = Navigator.getWindow() // to make sure UIWindow that show banner is same as main Window
        DispatchQueue.main.async {
            banner.show()
        }
    }

    static func hide() {
        DispatchQueue.main.async {
            banner.dismiss()
        }
    }
}

class CustomBannerColors: BannerColorsProtocol {
    func color(for style: BannerStyle) -> UIColor {
        switch style {
        case .danger:   return UIColor(hexString: "#828180")!
        case .info:     return UIColor(red:0.23, green:0.60, blue:0.85, alpha:1.00)
        case .customView:     return UIColor.clear
        case .success:  return UIColor(red:0.22, green:0.80, blue:0.46, alpha:1.00)
        case .warning:  return UIColor(red:1.00, green:0.66, blue:0.16, alpha:1.00)
        }
    }
}
