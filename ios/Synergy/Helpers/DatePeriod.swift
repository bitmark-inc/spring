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
}

extension Array where Element == DatePeriod {
    func asString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    func add(newDatePeriod: DatePeriod) -> [DatePeriod] {
        var updatedDatePeriods = self
        var isNotOverlapped: Bool = true

        (0..<self.count).forEach { (index) in
            var datePeriod = updatedDatePeriods[index]

            if datePeriod.isOverlap(with: newDatePeriod) {
                isNotOverlapped = false
                datePeriod = DatePeriod(
                    startDate: Swift.min(newDatePeriod.startDate, datePeriod.startDate),
                    endDate: Swift.max(newDatePeriod.endDate, datePeriod.endDate))
                updatedDatePeriods[index] = datePeriod
            }
        }

        if isNotOverlapped {
            updatedDatePeriods.append(newDatePeriod)
        }

        return updatedDatePeriods
    }
}
