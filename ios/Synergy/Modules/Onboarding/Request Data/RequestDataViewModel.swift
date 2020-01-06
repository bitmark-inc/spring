//
//  RequestDataViewModel.swift
//  Synergy
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import OneSignal

enum Mission {
    case requestData
    case checkRequestedData
    case downloadData
}

class RequestDataViewModel: ViewModel {

    // MARK: - Properties
    var login: String?
    var password: String?
    var mission: Mission!

    // MARK: - Output
    let fbScriptsRelay = BehaviorRelay<[FBScript]>(value: [])
    let fbScriptResultSubject = PublishSubject<Event<Void>>()
    let signUpAndSubmitArchiveResultSubject = PublishSubject<Event<Never>>()

    init(login: String? = nil, password: String? = nil, _ mission: Mission) {
        super.init()
        self.login = login
        self.password = password
        self.mission = mission

        self.setup()
    }

    func setup() {
        ServerAssetsService.getFBAutomation()
            .subscribe(onSuccess: { [weak self] (fbScripts) in
                self?.fbScriptsRelay.accept(fbScripts)
            },
            onError: { [weak self] (error) in
                self?.fbScriptResultSubject.onNext(Event.error(error))
            })
            .disposed(by: disposeBag)
    }

    func getFBCredential() -> Single<(username: String, password: String)> {
        return Single.just((username: login, password: password))
            .flatMap { (credential) -> Single<(username: String, password: String)> in
                guard credential.username != nil, credential.password != nil else {
                    return KeychainStore.getFBCredentialToKeychain()
                }
                return Single.just((username: credential.username!, password: credential.password!))
            }
            .do(onSuccess: { [weak self] in
                self?.login = $0.username; self?.password = $0.password
            })
    }

    func signUpAndSubmitFBArchive(headers: [String: String], archiveURL: URL, rawCookie: String) {
        loadingState.onNext(.loading)

        let createdAccounCompletable = Completable.deferred {
            if Global.current.account != nil {
                return Completable.empty()
            } else {
                return AccountService.rx.createNewAccount()
                    .flatMapCompletable({
                        Global.current.account = $0
                        AccountService.registerIntercom(for: $0.getAccountNumber())
                        return Global.current.setupCoreData()
                    })
            }
        }

        let fbArchiveCreatedAtTime: Date!
        if let fbArchiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt {
            fbArchiveCreatedAtTime = fbArchiveCreatedAt
        } else {
            fbArchiveCreatedAtTime = Date()
            Global.log.error(AppError.emptyFBArchiveCreatedAtInUserDefaults)
        }

        createdAccounCompletable
            .andThen(FbmAccountService.create())
            .catchErrorJustReturn(FbmAccount())
            .flatMapCompletable({ [weak self] (_) -> Completable in
                guard let self = self,
                    let accountNumber = Global.current.account?.getAccountNumber() else {
                        return Completable.never()
                }

                guard UserDefaults.standard.enablePushNotification else {
                    return Completable.empty()
                }

                return self.registerOneSignal(accountNumber: accountNumber)
            })
            .andThen(
                FBArchiveService.submit(
                    headers: headers,
                    fileURL: archiveURL.absoluteString,
                    rawCookie: rawCookie,
                    startedAt: nil,
                    endedAt: fbArchiveCreatedAtTime))
            .asObservable()
            .materialize().bind { [weak self] in
                loadingState.onNext(.hide)
                self?.signUpAndSubmitArchiveResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }
    
    fileprivate func registerOneSignal(accountNumber: String) -> Completable {
        Global.log.info("[process] registerOneSignal: \(accountNumber)")
        OneSignal.promptForPushNotifications(userResponse: { _ in
          OneSignal.sendTags([
            Constant.OneSignalTag.key: accountNumber
          ])
        })

        return Completable.empty()
    }
}
