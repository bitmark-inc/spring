//
//  LaunchingViewModel.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

class LaunchingViewModel: ViewModel {

    func gotoSignInWallScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel))
    }

    func gotoHowItWorksScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel))
    }

    func gotoSignInScreen() {

    }
}
