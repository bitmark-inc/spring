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

enum Mission {
    case requestData
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
                }, onError: { [weak self] (error) in
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
                        return Global.current.setupCoreData()
                    })
            }
        }

        createdAccounCompletable
            .andThen(FbmAccountService.create())
            .flatMapCompletable { _ in
                return FBArchiveService.submit(
                    headers: headers,
                    fileURL: archiveURL.absoluteString,
                    rawCookie: rawCookie
                )
            }
            .asObservable()
            .materialize().bind { [weak self] in
                loadingState.onNext(.hide)
                self?.signUpAndSubmitArchiveResultSubject.onNext($0)
            }
            .disposed(by: disposeBag)
    }

    func gotoDataRequested() {
        let viewModel = DataRequestedViewModel()
        navigator.show(segue: .dataRequested(viewModel: viewModel))
    }

    func gotoDataGenerating() {
        let viewModel = DataGeneratingViewModel()
        navigator.show(segue: .dataGenerating(viewModel: viewModel))
    }
}
