//
//  BiometricAuth.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import LocalAuthentication
import RxSwift

enum LAType {
    case touchID
    case faceID
    case passcode
    case none

    var text: String {
        switch self {
        case .touchID:  return R.string.localizable.biometricTouchID()
        case .faceID:   return R.string.localizable.biometricFaceID()
        case .passcode: return R.string.localizable.biometricPasscode()
        default:        return ""
        }
    }
}

class BiometricAuth {
    static var context = LAContext()

    static func currentDeviceEvaluatePolicyType() -> LAType {
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return context.biometryType == .faceID ? .faceID : .touchID
        }
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return .passcode
        }
        return .none
    }

    static func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static func authorizeAccess(reason: String = R.string.localizable.yourAuthorizationIsRequired()) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            self.context = LAContext()
            let disposable = Disposables.create()

            guard self.canEvaluatePolicy() else {
                completable(.error(AppError.biometricNotConfigured))
                return disposable
            }

            self.context.evaluatePolicy(
                LAPolicy.deviceOwnerAuthentication,
                localizedReason: reason) { (isSuccess, evaluateError) in
                    isSuccess ?
                        completable(.completed) :
                        completable(.error(AppError.biometricError))
            }
            return disposable
        })
    }
}
