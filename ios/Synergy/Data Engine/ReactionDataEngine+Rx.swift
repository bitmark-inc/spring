//
//  ReactionDataEngion+Rx.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import SwiftDate

class ReactionDataEngine {
    static func sync(datePeriod: DatePeriod?) {
        guard let datePeriod = datePeriod else { return }

        var startDate = min(datePeriod.endDate, Date())
        var endDate = startDate

        repeat {
            endDate = startDate
            startDate = max(startDate - 30.days, datePeriod.startDate)

            _ = ReactionService.getAll(startDate: startDate, endDate: endDate)
                .flatMapCompletable { Storage.store($0, inGlobalRealm: true) }
                .observeOn(SerialDispatchQueueScheduler(qos: .background))
                .subscribe(onError: { (error) in
                    guard !AppError.errorByNetworkConnection(error) else { return }
                    Global.log.error(error)
                })

        } while startDate > datePeriod.startDate
    }
}

extension ReactionDataEngine: ReactiveCompatible {}

extension Reactive where Base: ReactionDataEngine {

    static func fetch(with filterScope: FilterScope) -> Single<Results<Reaction>> {
        Global.log.info("[start] ReactionDataEngion.rx.fetch")

        return Single<Results<Reaction>>.create { (event) -> Disposable in
            do {
                guard Thread.current.isMainThread else {
                    throw AppError.incorrectThread
                }

                let realm = try RealmConfig.globalRealm()

                guard let filterQuery = makeFilterQuery(filterScope) else {
                    throw AppError.incorrectReactionFilter
                }
                let reactions = realm.objects(Reaction.self).filter(filterQuery)
                event(.success(reactions))

                let datePeriod = extractQueryDatePeriod(filterScope)
                ReactionDataEngine.sync(datePeriod: datePeriod)
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
            guard let type = filterScope.filterValue as? ReactionType else { break }
            filterPredicate = NSPredicate(format: "reaction == %@", type.rawValue)
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
