//
//  Application.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

final class Application: NSObject {
    static let shared = Application()

    var window: UIWindow?
    let navigator: Navigator

    private override init() {
        navigator = Navigator.default
        super.init()
        updateProvider()
    }

    private func updateProvider() {
    }

    func presentInitialScreen(in window: UIWindow?) {
        updateProvider()
        guard let window = window else { return }
        self.window = window

        let viewModel = LaunchingViewModel()
        self.navigator.show(segue: .launchingNavigation(viewModel: viewModel), sender: nil, transition: .root(in: window))
    }
}
