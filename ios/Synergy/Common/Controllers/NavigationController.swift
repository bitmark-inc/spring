//
//  NavigationController.swift
//  Synergy
//
//  Created by Anh Nguyen on 10/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class NavigationController: UINavigationController {
    let disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return globalStatusBarStyle.value
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        themeService.switchThemeType(for: traitCollection.userInterfaceStyle)
        navigationBar.isTranslucent = false
        navigationBar.shadowImage = UIImage()

        // Do any additional setup after loading the view.
        interactivePopGestureRecognizer?.delegate = nil // Enable default iOS back swipe gesture

        navigationBar.setTitleFont(UIFont.navigationTitleFont)

        themeService.rx
            .bind({ $0.textColor }, to: navigationBar.rx.tintColor)
            .bind({ $0.background }, to: navigationBar.rx.barTintColor)
            .disposed(by: disposeBag)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        themeService.switchThemeType(for: traitCollection.userInterfaceStyle)
    }
}
