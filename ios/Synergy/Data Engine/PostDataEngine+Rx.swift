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
import RxCocoa
import SwiftDate

enum LoadDataEvent {
    case triggerRemoteLoad
    case remoteLoaded
}

class PostDataEngine {

    static var datePeriodSubject: PublishSubject<DatePeriod>?
    static var triggerSubject: PublishSubject<LoadDataEvent>?

    static func sync(datePeriod: DatePeriod?) throws {
        guard let datePeriod = datePeriod else { return }

        datePeriodSubject = PublishSubject<DatePeriod>()

        let realm = try RealmConfig.currentRealm()
        let queryTrack = realm.object(ofType: QueryTrack.self, forPrimaryKey: RemoteQuery.posts.rawValue)
        let trackedDatePeriods = queryTrack?.datePeriods ?? []
        let rootEndDate = datePeriod.endDate

        var syncedStartDate: Date?

        guard let datePeriodSubject = datePeriodSubject, let triggerSubject = triggerSubject else { return }
        let triggeredDatePeriodObserver = PublishSubject
            .zip(
                datePeriodSubject,
                triggerSubject.filter { $0 == .triggerRemoteLoad })
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { (datePeriod, _) in
                let (startDate, endDate) = (datePeriod.startDate, datePeriod.endDate)
                _ = fetchRemote(startDate: startDate, endDate: endDate)
                    .subscribe(onSuccess: { (syncedSt) in
                        loadingState.onNext(.hide)
                        syncedStartDate = syncedSt

                        guard let syncedStartDate = syncedStartDate else { return }
                        if syncedStartDate <= startDate {
                            datePeriodSubject.onCompleted()
                        } else {
                            Self.datePeriodSubject?.onNext(
                                DatePeriod(startDate: startDate, endDate: syncedStartDate - 1.seconds))
                        }
                        triggerSubject.onNext(.remoteLoaded)
                    }, onError: { (error) in
                        guard !AppError.errorByNetworkConnection(error) else {
                            loadingState.onNext(.hide)
                            return
                        }
                        Global.log.error(error)
                    })
            }, onError: { (error) in
                if let error = error as? AppError {
                    switch error {
                    case .didRemoteQuery: break
                    default:
                        Global.log.error(error)
                    }
                } else {
                    Global.log.error(error)
                }
            })

        _ = datePeriodSubject
            .subscribe(onCompleted: {
                triggeredDatePeriodObserver.dispose()
                if let syncedStartDate = syncedStartDate {
                    QueryTrack.store(
                        trackedDatePeriods: trackedDatePeriods, in: .posts,
                        syncedDatePeriod: DatePeriod(startDate: syncedStartDate, endDate: rootEndDate))
                }
            })

        let shortenPeriod: DatePeriod?
        if let queryTrack = queryTrack {
            shortenPeriod = queryTrack.removeQueriedPeriod(for: datePeriod)
        } else {
            shortenPeriod = datePeriod
        }

        if let shortenPeriod = shortenPeriod {
            datePeriodSubject.onNext(shortenPeriod)

            if shortenPeriod.endDate.appTimeFormat == datePeriod.endDate.appTimeFormat {
                triggerSubject.onNext(.triggerRemoteLoad)
            }
        } else {
            loadingState.onNext(.hide)
            datePeriodSubject.onError(AppError.didRemoteQuery) // this is not error, just track to ignore waste to store QueryTrack
        }
    }

    static func fetchRemote(startDate: Date, endDate: Date) -> Single<Date> {
        return PostService.getAll(startDate: startDate, endDate: endDate)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap({ (posts) -> Single<Date> in
                let syncedStartDate = posts.compactMap { $0.timestamp }.min() ?? startDate
                return Storage.store(posts)
                    .andThen(Single.just(syncedStartDate))
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

                let realm = try RealmConfig.currentRealm()
                PostDataEngine.triggerSubject = PublishSubject<LoadDataEvent>()

                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectPostFilter
                }
                let posts = realm.objects(Post.self).filter(filterQuery)
                event(.success(posts))

                if posts.count == 0 { loadingState.onNext(.loading) }

                let datePeriod = extractQueryDatePeriod(filterScope)
                try PostDataEngine.sync(datePeriod: datePeriod)
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
            if let friends = filterScope.filterValue as? [String] {
                filterPredicate = NSPredicate(format: "ANY tags.name IN %@", friends)
            } else if let friend = filterScope.filterValue as? String {
                filterPredicate = NSPredicate(format: "ANY tags.name == %@", friend)
            }
        case .place:
            if let places = filterScope.filterValue as? [String] {
                filterPredicate = NSPredicate(format: "location.name IN %@", places)
            } else if let place = filterScope.filterValue as? String {
                filterPredicate = NSPredicate(format: "location.name == %@", place)
            }
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

enum RemoteQuery: String {
    case posts
    case reactions
}
