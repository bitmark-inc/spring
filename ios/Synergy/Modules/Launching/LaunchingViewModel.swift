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

    func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(.downloadData)
        navigator.show(segue: .requestData(viewModel: viewModel))
    }

    func gotoDataGeneratingScreen() {
        let viewModel = DataGeneratingViewModel()
        navigator.show(segue: .dataGenerating(viewModel: viewModel))
    }

    func gotoSignInScreen() {

    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs, transition: .replace(type: .auto))
    }
}
