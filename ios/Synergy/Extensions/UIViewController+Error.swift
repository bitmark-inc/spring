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
    showAlert(title: "Error".localized(), message: message, buttonTitles: ["OK".localized()])
  }

  func showErrorAlertWithSupport(message: String) {
    let supportMessage = String(format: "supportMessage".localized(), message)
    let alertController = UIAlertController(title: "Error".localized(), message: supportMessage, preferredStyle: .alert)

    let supportButton = UIAlertAction(title: "Contact".localized(), style: .default) { (_) in
      Intercom.presentMessenger()
    }

    alertController.addAction(title: "Cancel".localized(), style: .default, handler: nil)
    alertController.addAction(supportButton)
    alertController.preferredAction = supportButton
    alertController.show()
  }
}
