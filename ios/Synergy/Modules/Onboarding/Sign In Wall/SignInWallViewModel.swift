//
//  SignInWallViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SignInWallViewModel: ViewModel {

    // MARK: - Outputs
    var signUpResultSubject = PublishSubject<Event<Never>>()

    func gotoHowItWorksScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel))
    }

    func signUp() {
        loadingState.onNext(.loading)
        AccountService.rx.createNewAccount()
            .flatMapCompletable({
                Global.current.account = $0
                return Global.current.setupCoreData()
            })
            .asObservable()
            .materialize().bind { [weak self] in
              loadingState.onNext(.hide)
              self?.signUpResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }

    func goToSignInScreen() {
    }
}
