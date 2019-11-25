//
//  HowItWorksViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxFlow
import RxCocoa

class HowItWorksViewModel: ViewModel {

    func gotoGetYourDataScreen() {
        let viewModel = GetYourDataViewModel()
        navigator.show(segue: .getYourData(viewModel: viewModel))
    }
}
