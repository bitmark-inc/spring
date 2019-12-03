//
//  PostDataEngine+Rx.swift
//  Synergy
//
//  Created by thuyentruong on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftDate

class PostDataEngine {}

extension PostDataEngine: ReactiveCompatible {}

extension Reactive where Base: PostDataEngine {

    static func fetch(with filterScope: FilterScope) -> Single<Results<Post>> {
        Global.log.info("[start] PostDataEngine.rx.fetch")

        return Single<Results<Post>>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.currentRealm()

                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectPostFilter
                }
                let posts = realm.objects(Post.self).filter(filterQuery)
                event(.success(posts))

                _ = PostService.getAll()
                    .flatMapCompletable { Storage.store($0) }
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onError: { (error) in
                        guard !AppError.errorByNetworkConnection(error) else { return }
                        Global.log.error(error)
                    })
            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }

    static func makeFilterQuery(_ filterScope: FilterScope) -> NSCompoundPredicate? {
        let (_, timeUnit, date) = filterScope.usageScope

        guard let periodUnit = TimeUnit(rawValue: timeUnit) else { return nil }
        let startDate: NSDate!
        let endDate: NSDate!

        switch periodUnit {
        case .week:
            startDate = date.dateAtStartOf(.weekOfYear) as NSDate
            endDate = date.dateAtEndOf(.weekOfYear) as NSDate
        case .year:
            startDate = date.dateAtStartOf(.year) as NSDate
            endDate = date.dateAtEndOf(.year) as NSDate
        case .decade:
            startDate = (date - 10.years).dateAtStartOf(.year) as NSDate
            endDate = date.dateAtEndOf(.year) as NSDate
        }

        let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate, endDate)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate])
    }
}
