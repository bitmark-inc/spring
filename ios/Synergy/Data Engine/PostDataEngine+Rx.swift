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
    static func syncPosts() {
        _ = PostService.getAll()
            .flatMapCompletable { Storage.store($0, inGlobalRealm: true) }
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onError: { (error) in
                guard !AppError.errorByNetworkConnection(error) else { return }
                Global.log.error(error)
            })
    }
}

var didLoad = false

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

                if !didLoad && realm.objects(Post.self).isEmpty {
                    didLoad = true
                    PostDataEngine.syncPosts()
                }

            } catch {
                event(.error(error))
            }

            return Disposables.create()
        }
    }

    static func makeFilterQueryByDate(_ filterScope: FilterScope) -> NSPredicate? {
        let timeUnit = filterScope.timeUnit; let date = filterScope.date

        let startDate: NSDate!
        let endDate: NSDate!

        switch timeUnit {
        case .week:
            startDate = date.dateAtStartOf(.weekOfMonth) as NSDate
            endDate = date.dateAtEndOf(.weekOfMonth) as NSDate
        case .year:
            startDate = date.dateAtStartOf(.year) as NSDate
            endDate = date.dateAtEndOf(.year) as NSDate
        case .decade:
            startDate = (date - 10.years).dateAtStartOf(.year) as NSDate
            endDate = date.dateAtEndOf(.year) as NSDate
        }

        return NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate, endDate)
    }

    static func makeFilterQuery(_ filterScope: FilterScope) -> NSCompoundPredicate? {
        let timeUnit = filterScope.timeUnit

        let datePeriod: (startDate: Date, endDate: Date)!
        if filterScope.filterBy == .day {
            guard let filterDay = filterScope.filterValue as? Date
                else {
                    Global.log.error("formatInDay is incorrect")
                    return nil
            }

            datePeriod = filterDay.extractSubPeriod(timeUnit: timeUnit)
        } else {
            datePeriod = filterScope.date.extractDatePeriod(timeUnit: timeUnit)
        }

        let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                        datePeriod.startDate as NSDate, datePeriod.endDate as NSDate)
        var filterPredicate: NSPredicate?

        switch filterScope.filterBy {
        case .type:
            guard let type = filterScope.filterValue as? PostType else { break }
            filterPredicate = NSPredicate(format: "type == %@", type.rawValue)
        case .friend:
            guard let friends = filterScope.filterValue as? [String] else { break }
            let friendValue = friends.first! + Constant.separator
            filterPredicate = NSPredicate(format: "friendTags CONTAINS %@", friendValue)
        case .place:
            guard let places = filterScope.filterValue as? [String] else { break }
            filterPredicate = NSPredicate(format: "location.name == %@", places.first!)
        default:
            break
        }

        var predicates: [NSPredicate] = [datePredicate]
        if let filterPredicate = filterPredicate {
            predicates.append(filterPredicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
