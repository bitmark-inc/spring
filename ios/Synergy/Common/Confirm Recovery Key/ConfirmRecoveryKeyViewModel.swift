//
//  ConfirmRecoveryKeyViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RealmSwift

class ConfirmRecoveryKeyViewModel: ViewModel {

    // MARK: - Properties
    let recoveryKeyStringRelay = BehaviorRelay(value: "")
    let recoveryKeyRelay = BehaviorRelay<[String]>(value: [])

    // MARK: - Outputs
    var submitEnabled: Driver<Bool>

    override init() {
        submitEnabled = recoveryKeyRelay
            .map { $0.count == Constant.default.numberOfPhrases }
            .asDriver(onErrorJustReturn: false)

        super.init()

        self.setup()
    }

    func setup() {
        recoveryKeyStringRelay
            .map { $0.recoveryKey() }
            .bind(to: recoveryKeyRelay)
            .disposed(by: disposeBag)
    }
}
