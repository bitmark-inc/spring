//
//  PostService.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import Moya

class PostService {

    static var provider = MoyaProvider<PostAPI>(plugins: Global.default.networkLoggerPlugin)

    static func getAll(startDate: Date, endDate: Date) -> Single<[Post]> {
        Global.log.info("[start] PostService.get(startDate, endDate)")


        return provider.rx.requestWithRefreshJwt(.get(startDate: startDate, endDate: endDate))
            .filterSuccess()
            .map([Post].self, atKeyPath: "result")
    }
}
