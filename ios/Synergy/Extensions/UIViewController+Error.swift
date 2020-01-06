//
//  UIViewController+Error.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import Intercom
import SwifterSwift

extension UIViewController {
    func showErrorAlert(message: String) {
        showAlert(
            title: R.string.error.generalTitle(),
            message: message,
            buttonTitles: [R.string.localizable.ok()])
    }

    func showErrorAlertWithSupport(message: String) {
        let supportMessage = R.string.localizable.supportMessage(message)
        let alertController = UIAlertController(
            title: R.string.error.generalTitle(),
            message: supportMessage,
            preferredStyle: .alert)

        let supportButton = UIAlertAction(title: R.string.localizable.contact(), style: .default) { (_) in
            Intercom.presentMessenger()
        }

        alertController.addAction(title: R.string.localizable.cancel(), style: .default, handler: nil)
        alertController.addAction(supportButton)
        alertController.preferredAction = supportButton
        alertController.show()
    }
}

struct ErrorAlert {
    static func showAuthenticationRequiredAlert(action: @escaping () -> Void) -> UIAlertController {
        let policyType = BiometricAuth.currentDeviceEvaluatePolicyType()
        let retryAuthenticationAlert = UIAlertController(
            title: R.string.error.biometricAuthRequired(policyType.text),
            message: R.string.error.biometricAuthDescription(policyType.text),
            preferredStyle: .alert)

        retryAuthenticationAlert.addAction(
            title: R.string.localizable.tryAgain(), style: .default,
            handler: { _ in action() })
        retryAuthenticationAlert.show()
        return retryAuthenticationAlert
    }
}
