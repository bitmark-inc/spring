//
//  SignOutViewModel.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Intercom

class SignOutViewModel: ConfirmRecoveryKeyViewModel {

    // MARK: - Outputs
    var signOutAccountResultSubject = PublishSubject<Event<Never>>()

    // MARK: - Handlers
    func signOutAccount() {
        do {
            guard try validRecoveryKey() else {
                signOutAccountResultSubject.onNext(
                    Event.error(AccountError.invalidRecoveryKey)
                )
                return
            }

            try KeychainStore.removeSeedCoreFromKeychain()

            // clear user data
            try FileManager.default.removeItem(at: FileManager.filesDocumentDirectoryURL)

            do {
                try FileManager.default.removeItem(at: FileManager.databaseDirectoryURL)
                try KeychainStore.removeEncryptedDBKeyFromKeychain()
            } catch {
                Global.log.error(error)
            }

            Global.current = Global() // reset local variable
            AuthService.shared = AuthService()
            Intercom.logout()
            ErrorReporting.setUser(bitmarkAccountNumber: nil)

            signOutAccountResultSubject.onNext(Event.completed)
        } catch {
            signOutAccountResultSubject.onNext(Event.error(error))
        }
    }

    func validRecoveryKey() throws -> Bool {
        guard let currentAccount = Global.current.account else { throw AppError.emptyCurrentAccount }

        let currentRecoveryKey = try currentAccount.getRecoverPhrase(language: .english)
        return recoveryKeyRelay.value == currentRecoveryKey
    }
}
