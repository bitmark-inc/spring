//
//  IncreasePrivacyViewModel.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa

class IncreasePrivacyViewModel: ViewModel {

    let increasePrivacyOption: IncreasePrivacyOption!

    init(increasePrivacyOption: IncreasePrivacyOption) {
        self.increasePrivacyOption = increasePrivacyOption
        super.init()
    }
}
