//
//  StreamViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class StreamViewModel: ViewModel {

    // MARK: - Inputs
    // MARK: - Outputs
    var signOutResultSubject = PublishSubject<Event<Never>>()

    func signOut() {
        do {
            try KeychainStore.removeSeedCoreFromKeychain()
            Global.current = Global() // reset local variable
            AuthService.shared = AuthService()
            signOutResultSubject.onNext(Event.completed)
        } catch {
            Global.log.error(error)
            signOutResultSubject.onNext(Event.error(error))
        }
    }
}

