//
//  DatePeriod.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/31/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import SwiftDate

struct DatePeriod: Codable {
    let startDate: Date
    let endDate: Date
}

extension DatePeriod {
    func makeTimelinePeriodText(in timeUnit: TimeUnit) -> String {
        switch timeUnit {
        case .week:
            return startDate.toFormat(Constant.TimeFormat.full) + "-" + endDate.toFormat(Constant.TimeFormat.short)
        case .year:
            return "\(startDate.toFormat("yyyy"))"
        case .decade:
            return "\(startDate.toFormat("yyyy"))-\(endDate.toFormat("yyyy"))"
        }
    }

    func makeTimelinePeriodText(in calendarComponent: Calendar.Component) -> String {
        switch calendarComponent {
        case .day:
            return startDate.toFormat(Constant.TimeFormat.full)
        case .month:
            return startDate.toFormat("YYYY MMM")
        case .year:
            return startDate.toFormat("yyyy")
        default:
            return ""
        }
    }

    func isOverlap(with datePeriod: DatePeriod) -> Bool {
        let notOverlap = datePeriod.endDate < startDate || datePeriod.startDate > endDate
        return !notOverlap
    }

    func isLinked(with datePeriod: DatePeriod) -> Bool {
        return (endDate + 1.seconds).appTimeFormat == datePeriod.startDate.appTimeFormat ||
            (datePeriod.endDate + 1.seconds).appTimeFormat == startDate.appTimeFormat
    }

    func isRelated(with datePeriod: DatePeriod) -> Bool {
        return isOverlap(with: datePeriod) || isLinked(with: datePeriod)
    }
}

extension DatePeriod: Equatable {
    static func ==(lhs: DatePeriod, rhs: DatePeriod) -> Bool {
        return lhs.startDate.appTimeFormat == rhs.startDate.appTimeFormat &&
            lhs.endDate.appTimeFormat == rhs.endDate.appTimeFormat
    }

    static func +(lhs: DatePeriod, rhs: DatePeriod) -> DatePeriod {
        return DatePeriod(
            startDate: Swift.min(lhs.startDate, rhs.startDate),
            endDate: Swift.max(lhs.endDate, rhs.endDate))
    }


    static func -(lhs: DatePeriod, rhs: DatePeriod) -> DatePeriod? {
        guard lhs.isOverlap(with: rhs) else { return nil }

        if lhs.startDate >= rhs.startDate && lhs.endDate <= rhs.endDate {
            return nil
        }

        // ignore thist to avoid cutting pieces remote queries complicated
        if lhs.startDate < rhs.startDate && lhs.endDate > rhs.endDate {
            return lhs
        }

        if lhs.endDate <= rhs.endDate {
            return DatePeriod(startDate: lhs.startDate, endDate: rhs.startDate - 1.seconds)
        }

        if lhs.endDate > rhs.endDate {
            return DatePeriod(startDate: rhs.endDate + 1.seconds, endDate: lhs.endDate)
        }

        return nil
    }
}

extension Array where Element == DatePeriod {
    func asString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    func add(newDatePeriod: DatePeriod) -> [DatePeriod] {
        var updatedDatePeriods = self
        var adjustedDatePeriod: DatePeriod?

        for datePeriod in self {
            if datePeriod.isRelated(with: newDatePeriod) {
                adjustedDatePeriod = datePeriod + newDatePeriod
                updatedDatePeriods.removeAll(datePeriod)
                break
            }
        }

        if let adjustedDatePeriod = adjustedDatePeriod {
            return updatedDatePeriods.add(newDatePeriod: adjustedDatePeriod)
        } else {
            updatedDatePeriods.append(newDatePeriod)
            return updatedDatePeriods
        }
    }
}
