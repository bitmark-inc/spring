//
//  FBArchiveService.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxSwift
import Moya

class FBArchiveService {

    static var provider = MoyaProvider<FBArchiveAPI>(plugins: Global.default.networkLoggerPlugin)

    static func submit(headers: [String: String], fileURL: String, rawCookie: String, startedAt: Date?, endedAt: Date) -> Completable {
        Global.log.info("[start] submitFBArchive")

        return provider.rx
            .requestWithRefreshJwt(.submit(headers: headers, fileURL: fileURL, rawCookie: rawCookie, startedAt: startedAt, endedAt: endedAt))
            .filterSuccess()
            .asCompletable()
    }

    static func getAll() -> Single<[Archive]> {
        Global.log.info("[start] getAll")

        return provider.rx
            .requestWithRefreshJwt(.getAll)
            .filterSuccess()
            .map([Archive].self, atKeyPath: "result", using: Global.default.decoder)
    }
}
