//
//  BitmarkSDKService.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import XCGLogger

class BitmarkSDKService {

  private static let networkMode: Network = {
    #if PRODUCTION
      return Network.livenet
    #else
      return Network.testnet
    #endif
  }()

  static func setupConfig() {
    let config = SDKConfig(apiToken: "", network: networkMode, urlSession: URLSession.shared, logger: BitmarkSDKServiceLogger())
    BitmarkSDK.initialize(config: config)
  }
}

class BitmarkSDKServiceLogger: SDKLogger {
  func log(level: SDKLogLevel, message: String) {
    Global.log.info(message)
  }
}
