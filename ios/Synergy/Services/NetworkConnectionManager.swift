//
//  NetworkConnectionManager.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

// An observable that completes when the app gets online (possibly completes immediately).
func connectedToInternet() -> Completable {
  Completable.deferred {
    let isReachable = NetworkConnectionManager.shared.isReachable
    return isReachable ?
      Completable.empty() :
      Completable.error(FlowError.noInternetConnection)
  }
}

class NetworkConnectionManager {

  static let shared = NetworkConnectionManager()
  let reachRelay = BehaviorRelay<Bool>(value: false)

  init() {
    guard let reachability = NetworkReachabilityManager() else { return }
    reachRelay.accept(reachability.isReachable)

    reachability.startListening(onUpdatePerforming: { [weak self] (status) in
      guard let self = self else { return }
      switch status {
      case .notReachable:
        self.reachRelay.accept(false)
      default:
        self.reachRelay.accept(true)
      }
    })
  }

  var isReachable: Bool {
    let isReachableResult = reachRelay.value
    isReachableResult ? NoInternetBanner.hide() : NoInternetBanner.show()
    return isReachableResult
  }
}
