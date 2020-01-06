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

    let accountRelay = BehaviorRelay<Account?>(value: nil)

    // MARK: - Outputs
    var signInResultSubject = PublishSubject<Event<ArchiveStatus?>>()

    func signInAccount() {
        Global.log.info("[start] signIn")

        loadingState.onNext(.loading)
        AccountService.rx.getAccount(phrases: recoveryKeyRelay.value)
            .do(onSuccess: { [weak self] in self?.accountRelay.accept($0) })
            .flatMap({ [weak self] (account) -> Single<FbmAccount> in
                Global.current.account = account
                self?.accountRelay.accept(account)
                return FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
            })
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

        accountRelay
            .subscribe(onNext: { (account) in
                guard let account = account else { return }
                Global.current.account = account
                AccountService.registerIntercom(for: account.getAccountNumber())
                _ = Global.current.setupCoreData()
                    .subscribe { (error) in
                        Global.log.error(error)
                    }
            })
            .disposed(by: disposeBag)
    }
}
