//
//  AuthService.swift
//  Synergy
//
//  Created by thuyentruong on 11/1/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxOptional
import Moya

class AuthService {

    static var shared = AuthService()
    static let current = shared

    // MARK: - Properties
    var auth: Auth?

    // MARK: Outputs
    var jwtCompletationSubject = PublishSubject<Event<Never>>()
    var jwtCompletable: Completable {
        Completable.deferred {
            return self.jwtCompletationSubject.take(1).dematerialize().ignoreElements()
        }
    }

    let provider = MoyaProvider<AuthAPI>(plugins: Global.default.networkLoggerPlugin)
    var lock = NSLock()
    let disposeBag = DisposeBag()

    // MARK: - Handlers
    func mutexRefreshJwt() {
        guard lock.try() else { return }

        refreshValidJwt()
            .asObservable().materialize()
            .bind { [weak self] in
                guard let self = self else { return }
                self.jwtCompletationSubject.onNext($0)
                self.lock.unlock()
        }.disposed(by: self.disposeBag)
    }

    func refreshValidJwt() -> Completable {
        return Completable.create { (event) -> Disposable in

            guard let currentAccount = Global.current.account else {
                event(.error(AppError.emptyCurrentAccount))
                return Disposables.create()
            }

            if let auth = self.auth, auth.expireIn <= Date() {
                event(.completed)
                Global.log.debug("get cached JWT")
            } else {
                _ = self.requestJwtForAccount(account: currentAccount)
                    .subscribe(onSuccess: { [weak self] (auth) in
                        self?.auth = auth
                        event(.completed)
                    }, onError: { (error) in
                        event(.error(error))
                    })
            }

            return Disposables.create()
        }
    }

    func requestJwtForAccount(account: Account) -> Single<Auth> {
        Single.deferred { [weak self] in
            guard let self = self else {
                return Single.never()
            }

            Global.log.info("[start] requestJwt")

            guard NetworkConnectionManager.shared.isReachable else {
                return Single.error(AppError.noInternetConnection)
            }

            let timestamp = Common.timestamp()
            var signature: Data!
            do {
                signature = try account.sign(message: timestamp.data(using: .utf8)!)
            } catch {
                return Single.error(error)
            }

            return self.provider.rx.onlineRequest(
                .auth(
                    accountNumber: account.getAccountNumber(),
                    timestamp: timestamp, signature: signature))
                .filterSuccess()
                .map(Auth.self)
                .do(onSuccess: { BitmarkSDK.setAPIToken($0.jwtToken) })
        }
    }
}
