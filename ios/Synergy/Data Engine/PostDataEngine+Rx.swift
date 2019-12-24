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

class PostDataEngine {
    static func syncPosts(datePeriod: DatePeriod?) {
        guard let datePeriod = datePeriod else { return }

        _ = PostService.getAll(startDate: datePeriod.startDate, endDate: datePeriod.endDate)
            .flatMapCompletable { Storage.store($0, inGlobalRealm: true) }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onError: { (error) in
                guard !AppError.errorByNetworkConnection(error) else { return }
                Global.log.error(error)
            })
    }
}

extension PostDataEngine: ReactiveCompatible {}

extension Reactive where Base: PostDataEngine {

    static func fetch(with filterScope: FilterScope) -> Single<Results<Post>> {
        Global.log.info("[start] PostDataEngine.rx.fetch")

        return Single<Results<Post>>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.globalRealm()

                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectPostFilter
                }
                let posts = realm.objects(Post.self).filter(filterQuery)
                event(.success(posts))

                let datePeriod = extractQueryDatePeriod(filterScope)
                PostDataEngine.syncPosts(datePeriod: datePeriod)

            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }

    static func makeFilterQuery(_ filterScope: FilterScope) -> NSCompoundPredicate? {
        guard let datePeriod = extractQueryDatePeriod(filterScope) else { return nil }
        let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                        datePeriod.startDate as NSDate, datePeriod.endDate as NSDate)
        var filterPredicate: NSPredicate?

        switch filterScope.filterBy {
        case .type:
            guard let type = filterScope.filterValue as? PostType else { break }
            filterPredicate = NSPredicate(format: "type == %@", type.rawValue)
        case .friend:
            guard let friends = filterScope.filterValue as? [String] else { break }
            filterPredicate = NSPredicate(format: "ANY tags.name IN %@", friends)
        case .place:
            guard let places = filterScope.filterValue as? [String] else { break }
            filterPredicate = NSPredicate(format: "location.name IN %@", places)
        default:
            break
        }

        var predicates: [NSPredicate] = [datePredicate]
        if let filterPredicate = filterPredicate {
            predicates.append(filterPredicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    static func extractQueryDatePeriod(_ filterScope: FilterScope) -> DatePeriod? {
        let timeUnit = filterScope.timeUnit

        switch filterScope.filterBy {
        case .day:
            guard let filterDay = filterScope.filterValue as? Date
                else {
                    Global.log.error("formatInDay is incorrect.")
                    return nil
            }

            return filterDay.extractSubPeriod(timeUnit: timeUnit)
        default:
            return filterScope.date.extractDatePeriod(timeUnit: timeUnit)
        }
    }
}
