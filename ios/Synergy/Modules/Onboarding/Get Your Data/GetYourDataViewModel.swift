//
//  GetYourDataViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/20/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa

class GetYourDataViewModel: ViewModel {

    // MARK: - Inputs
    let loginRelay = BehaviorRelay(value: "")
    let passwordRelay = BehaviorRelay(value: "")

    // MARK: - Outputs
    var automateAuthorizeBtnEnabled: Driver<Bool>!

    override init() {
        super.init()
        self.setup()
    }

    func setup() {
        automateAuthorizeBtnEnabled = BehaviorRelay.combineLatest(loginRelay, passwordRelay) {
            $0.isNotEmpty && $1.isNotEmpty
        }
        .asDriver(onErrorJustReturn: false)
    }

    func gotoRequestData() {
//        let viewModel = RequestDataViewModel(login: loginRelay.value, password: passwordRelay.value, .requestData)
//        navigator.show(segue: .requestData(viewModel: viewModel))
    }
}
