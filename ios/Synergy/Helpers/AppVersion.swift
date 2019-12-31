//
//  AppVersion.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class AppVersion {
    static func checkAppVersion() -> Completable {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let buildVersionNumber = Int(bundleVersion)
            else {
                return Completable.never()
        }

        return Completable.create { (event) -> Disposable in
            _ = ServerAssetsService.getAppInformation()
                .subscribe(onSuccess: { (iosInfo) in
                    guard let minimumClientVersion = iosInfo.minimumClientVersion else { return }
                    if buildVersionNumber < minimumClientVersion {
                        guard let appUpdatePath = iosInfo.appUpdateURL, let appUpdateURL = URL(string: appUpdatePath) else { return }
                        event(.error(AppError.requireAppUpdate(updateURL: appUpdateURL)))
                    } else {
                        event(.completed)
                    }
                })

            return Disposables.create()
        }
    }

    static func showAppRequireUpdateAlert(updateURL: URL) {
        let alertController = UIAlertController(
            title: R.string.localizable.requireAppUpdateTitle(),
            message: R.string.localizable.requireAppUpdateMessage(),
            preferredStyle: .alert)

        alertController.addAction(title: R.string.localizable.requireAppUpdateAction(), style: .default) { (_) in
            UIApplication.shared.open(updateURL)
        }

        alertController.show()
    }
}
