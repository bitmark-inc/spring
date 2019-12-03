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

    static func getAll() -> Single<[Post]> {
        guard let url = Bundle.main.url(forResource: "posts", withExtension: "json") else {
            return Single.never()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([Post].self, from: data)
            return Single.just(jsonData)
        } catch {
            return Single.error(error)
        }
    }
}
