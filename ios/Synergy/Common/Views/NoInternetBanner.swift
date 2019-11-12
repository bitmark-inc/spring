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

  static let banner = StatusBarNotificationBanner(
    title: "NoInternetConnection".localized(),
    style: .danger
  )

  static func show() {
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
