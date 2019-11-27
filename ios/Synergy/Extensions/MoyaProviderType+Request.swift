//
//  MoyaProviderType+Request.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

extension Reactive where Base: MoyaProviderType {
    func onlineRequest(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Single<Response> {
        let actualRequest = request(token)

        return connectedToInternet()
            .andThen(actualRequest)
    }

    func onlineRequestWithProgress(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Observable<ProgressResponse> {
        let actualRequestWithProgress = requestWithProgress(token)

        return connectedToInternet()
            .andThen(actualRequestWithProgress)
    }

    func requestWithRefreshJwt(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Single<Response> {
        let actualRequest = request(token)

        return AuthService.shared.jwtCompletable
            .do(onSubscribed: { AuthService.shared.mutexRefreshJwt() })
            .andThen(connectedToInternet())
            .andThen(actualRequest)
    }

    func requestWithProgressAndRequestJwt(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> Observable<ProgressResponse> {
        let actualRequestWithProgress = requestWithProgress(token)

        return AuthService.shared.jwtCompletable
            .do(onSubscribed: { AuthService.shared.mutexRefreshJwt() })
            .andThen(connectedToInternet())
            .andThen(actualRequestWithProgress)
    }
}
