//
//  ViewRecoveryKeyViewModel.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa

class ViewRecoveryKeyViewModel: ViewModel {

    // MARK: - Outputs
    let currentRecoveryKeyRelay = BehaviorRelay<[String]>(value: [])

    override init() {
        super.init()
        self.setup()
    }

    func setup() {
        do {
            guard let currentAccount = Global.current.account else { return }
            self.currentRecoveryKeyRelay.accept(
                try currentAccount.getRecoverPhrase(language: .english)
            )
        } catch {
            Global.log.error(error)
        }
    }
}
