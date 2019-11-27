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

    static func submit(headers: [String: String], fileURL: String, rawCookie: String) -> Completable {
        Global.log.info("[start] submitFBArchive")

        return provider.rx
            .requestWithRefreshJwt(.submit(headers: headers, fileURL: fileURL, rawCookie: rawCookie))
            .filterSuccess()
            .asCompletable()
    }
}
