//
//  ImageService.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import Kingfisher

class ImageService {

    static func makePhotoURL(key: String) -> Single<(photoURL: URL, modifier: AnyModifier)> {
        var photoURL = URL(string: Constant.fbImageServerURL)!
        photoURL.appendQueryParameters(["key": key.urlEncoded])

        return Single.create { (event) -> Disposable in
            _ = AuthService.shared.jwtCompletable
                .do(onSubscribed: { AuthService.shared.mutexRefreshJwt() })
                .andThen(connectedToInternet())
                .subscribe(onCompleted: {

                    let modifier = AnyModifier { request in
                        var request = request
                        if let token = AuthService.shared.auth?.jwtToken {
                            request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
                        }
                        return request
                    }

                    event(.success((photoURL: photoURL, modifier: modifier)))
                }, onError: { (error) in
                    event(.error(error))
                })
            return Disposables.create()
        }
    }
}
