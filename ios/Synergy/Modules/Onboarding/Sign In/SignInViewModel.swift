//
//  SignInViewModel.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BitmarkSDK
import Intercom

class SignInViewModel: ConfirmRecoveryKeyViewModel {

    // MARK: - Outputs
    var signInResultSubject = PublishSubject<Event<ArchiveStatus?>>()

    func signInAccount() {
        Global.log.info("[start] signIn")

        loadingState.onNext(.loading)

        let setupAccountCompletable = Completable.deferred {
            guard let account = Global.current.account else {
                return Completable.never()
            }

            AccountService.registerIntercom(for: account.getAccountNumber())
            SettingsBundle.setAccountNumber(accountNumber: account.getAccountNumber())
            return Global.current.setupCoreData()
        }

        AccountService.rx.getAccount(phrases: recoveryKeyRelay.value)
            .flatMap { (account) -> Single<FbmAccount> in
                Global.current.account = account
                return setupAccountCompletable
                    .andThen(FbmAccountDataEngine.rx.fetchCurrentFbmAccount())
            }
            .flatMap { _ in FbmAccountService.fetchOverallArchiveStatus() }
            .do(onSuccess: { (archiveStatus) in
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
            })
            .catchError({ (error) -> Single<ArchiveStatus?> in
                if AppError.errorByNetworkConnection(error) {
                    return Single.just(ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? ""))
                } else {
                    return Single.error(error)
                }
            })
            .asObservable()
            .materialize().bind { [weak self] in
                loadingState.onNext(.hide)
                self?.signInResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }
}
