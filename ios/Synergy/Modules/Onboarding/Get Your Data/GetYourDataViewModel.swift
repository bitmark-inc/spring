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

    // MARK: - Properties
    var missions = [Mission]()

    // MARK: - Inputs
    let loginRelay = BehaviorRelay(value: "")
    let passwordRelay = BehaviorRelay(value: "")

    let resultSubject = PublishSubject<Event<Never>>()

    // MARK: - Outputs
    var automateAuthorizeBtnEnabled: Driver<Bool>!

    init(missions: [Mission]) {
        super.init()
        self.missions = missions

        self.setup()
    }

    func setup() {
        automateAuthorizeBtnEnabled = BehaviorRelay.combineLatest(loginRelay, passwordRelay) {
            $0.isNotEmpty && $1.isNotEmpty
        }.asDriver(onErrorJustReturn: false)
    }

    func isValidFBCredential() -> Single<Bool> {
        Single.deferred {
            guard Global.current.account != nil else {
                return Single.just(true)
            }

            return FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .map { [weak self] (fbmAccount) in
                    guard let self = self else { return false }
                    let usernameInput = self.loginRelay.value
                    if let fbIdentifier = try Converter<Metadata>(from: fbmAccount.metadata).value.fbIdentifier {
                        return usernameInput.sha3() == fbIdentifier
                    } else {
                        return true
                    }
                }
        }
    }

    func saveFBCredentialToKeychain() {
        do {
            try KeychainStore.saveFBCredentialToKeychain(loginRelay.value, password: passwordRelay.value)
        } catch {
            Global.log.error(error)
        }
    }
}
