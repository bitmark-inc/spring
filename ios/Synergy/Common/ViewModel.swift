//
//  ViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RxFlow

class ViewModel: Stepper, Navigatable {
    var navigator: Navigator! = Navigator.default

    let steps = PublishRelay<Step>()
    let disposeBag = DisposeBag()
}
