//
//  MediaService.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import RxSwift
import Kingfisher
import AVFoundation

class MediaService {

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
                        request.allHTTPHeaderFields = makeMediaHeaders()
                        return request
                    }

                    event(.success((photoURL: photoURL, modifier: modifier)))
                }, onError: { (error) in
                    event(.error(error))
                })
            return Disposables.create()
        }
    }

    static func makeVideoURL(key: String) -> Single<AVURLAsset> {
        var videoURL = URL(string: Constant.fbImageServerURL)!
            videoURL.appendQueryParameters(["key": key.urlEncoded])

            return Single.create { (event) -> Disposable in
                _ = AuthService.shared.jwtCompletable
                    .do(onSubscribed: { AuthService.shared.mutexRefreshJwt() })
                    .andThen(connectedToInternet())
                    .subscribe(onCompleted: {
                        let asset = AVURLAsset(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": makeMediaHeaders()])
                        event(.success(asset))
                    }, onError: { (error) in
                        event(.error(error))
                    })
                return Disposables.create()
            }
        }

    static func makeMediaHeaders() -> [String: String] {
        guard let token = AuthService.shared.auth?.jwtToken,
            let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            else {
                return [:]
        }

        return [
            "Authorization": "Bearer " + token,
            "Client-Type": "ios",
            "Client-Version": bundleVersion
        ]
    }
}
