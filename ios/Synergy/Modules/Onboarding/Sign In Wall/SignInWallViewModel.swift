//
//  SignInWallViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxFlow
import RxCocoa

class SignInWallViewModel: ViewModel {

    func goToSignUpScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel))
    }

    func goToSignInScreen() {
    }
}
