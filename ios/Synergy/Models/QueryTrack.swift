//
//  QueryTrack.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import SwiftDate

class QueryTrack: Object, Decodable {

    // MARK: - Properties
    @objc dynamic var query: String = ""
    @objc dynamic var datePeriodsStr: String = ""

    override static func primaryKey() -> String? {
        return "query"
    }
}

extension QueryTrack {
    var datePeriods: [DatePeriod] {
        guard let jsonData = datePeriodsStr.data(using: .utf8)
            else {
                Global.log.error("invalid datePeriod string")
                return []
        }
        do {
            return try JSONDecoder().decode([DatePeriod].self, from: jsonData)
        } catch {
            Global.log.error(error)
            return  []
        }
    }

    func removeQueriedPeriod(for newDatePeriod: DatePeriod) -> DatePeriod? {
        var shortenDatePeriod: DatePeriod? = newDatePeriod
        for datePeriod in datePeriods {
            if shortenDatePeriod!.isOverlap(with: datePeriod) {
                shortenDatePeriod = shortenDatePeriod! - datePeriod
                if shortenDatePeriod == nil {
                    break
                }
            }
        }
        return shortenDatePeriod
    }

    static func store(trackedDatePeriods: [DatePeriod], in remoteQuery: RemoteQuery, syncedDatePeriod: DatePeriod) {
        let updatedtrackedDatePeriods = trackedDatePeriods.add(newDatePeriod: syncedDatePeriod)
        let updatedtrackedDatePeriodStr: String!
        do {
            updatedtrackedDatePeriodStr = try updatedtrackedDatePeriods.asString()
        } catch {
            Global.log.error(error)
            updatedtrackedDatePeriodStr = ""
        }

        let newQueryTrack = QueryTrack()
        newQueryTrack.datePeriodsStr = updatedtrackedDatePeriodStr
        newQueryTrack.query = remoteQuery.rawValue

        _ = Storage.store(newQueryTrack)
            .subscribe(onError: { (error) in
                Global.log.error(error)
            })
    }
}
