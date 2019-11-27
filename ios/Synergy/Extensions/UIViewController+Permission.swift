//
//  UIViewController+Permission.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import UserNotifications

extension UIViewController {

    func askForNotificationPermission() -> Single<UNAuthorizationStatus> {
        return Single<UNAuthorizationStatus>.create { (event) -> Disposable in
            let notificationCenter = UNUserNotificationCenter.current()

            notificationCenter.getNotificationSettings { (settings) in

                let notifyStatus = settings.authorizationStatus
                switch notifyStatus {
                case .denied:
                    self.askEnableNotificationAlert()

                case .notDetermined:
                    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                    notificationCenter.requestAuthorization(options: options) { (didAllow, error) in
                        if let error = error {
                            event(.error(error))
                        } else {
                            didAllow ? event(.success(.authorized)) : event(.success(.denied))
                        }
                    }

                case .authorized, .provisional:
                    event(.success(notifyStatus))
                @unknown default:
                    break
                }
            }

            return Disposables.create()
        }
    }

    func askEnableNotificationAlert() {
        let alertController = UIAlertController(
            title: R.string.error.notificationTitle(),
            message: R.string.error.notificationMessage(),
            preferredStyle: .alert)

        alertController.addAction(
            title: R.string.localizable.enable(),
            style: .default, handler: openAppSettings)

        alertController.show()
    }

    @objc func openAppSettings(_ sender: UIAlertAction) {
        guard let url = URL.init(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
