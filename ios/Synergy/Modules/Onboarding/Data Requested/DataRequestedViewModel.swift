//
//  DataRequestedViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

class DataRequestedViewModel: ViewModel {
    
    // MARK: - Properties
    var mission: Mission!
    
    init(_ mission: Mission) {
        super.init()
        self.mission = mission
    }
}
