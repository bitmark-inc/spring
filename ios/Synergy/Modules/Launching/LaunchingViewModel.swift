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

    func gotoSignInScreen() {

    }
}
