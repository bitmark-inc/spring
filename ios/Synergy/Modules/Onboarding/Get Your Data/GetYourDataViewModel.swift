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
        }.asDriver(onErrorJustReturn: false)
    }

    func gotoRequestData() {
        do {
            try KeychainStore.saveFBCredentialToKeychain(loginRelay.value, password: passwordRelay.value)
        } catch {
            Global.log.error(error)
        }

        let viewModel = RequestDataViewModel(login: loginRelay.value, password: passwordRelay.value, .requestData)
        navigator.show(segue: .requestData(viewModel: viewModel))
    }

    func fakeCreateAccountAndgotoAnalyzingScreen() {
        loadingState.onNext(.loading)

        let createdAccounCompletable = Completable.deferred {
            if Global.current.account != nil {
                return Completable.empty()
            } else {
                return AccountService.rx.createNewAccount()
                    .flatMapCompletable({
                        Global.current.account = $0
                        return Global.current.setupCoreData()
                    })
            }
        }

        createdAccounCompletable
            .andThen(FbmAccountService.create())
            .asObservable()
            .subscribe(onNext: { [weak self] (_) in
                loadingState.onNext(.hide)
                self?.gotoDataAnalyzing()
            })
            .disposed(by: disposeBag)
    }

    func gotoDataAnalyzing() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel))
    }
}
