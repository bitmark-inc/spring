//
//  Date+Extension.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import SwiftDate

extension Date {
    func `in`(_ locale: Locales) -> DateInRegion {
        let defaultRegion = SwiftDate.defaultRegion
        let newRegion = Region(calendar: defaultRegion.calendar, zone: defaultRegion.timeZone, locale: Locales.english)

        return date.in(region: newRegion)
    }

    func extractDatePeriod(timeUnit: TimeUnit, locale: Locales = .english) -> DatePeriod {
        let dateRegion = self.in(locale)
        switch timeUnit {
        case .week:
            return DatePeriod(
                startDate: dateRegion.dateAtStartOf(.weekOfMonth).date,
                endDate: dateRegion.dateAtEndOf(.weekOfMonth).date)
        case .year:
            return DatePeriod(
                startDate: dateRegion.dateAtStartOf(.year).date,
                endDate: dateRegion.dateAtEndOf(.year).date)
        case .decade:
            return DatePeriod(
                startDate: dateRegion.dateAtStartOfDecade().date,
                endDate: dateRegion.dateAtEndOfDecade().date)
        }
    }

    func extractSubPeriod(timeUnit: TimeUnit, locale: Locales = .english) -> DatePeriod {
        let dateRegion = self.in(locale)
        switch timeUnit {
        case .week:
            return DatePeriod(
                startDate: dateRegion.dateAtStartOf(.day).date,
                endDate: dateRegion.dateAtEndOf(.day).date)
        case .year:
            return DatePeriod(
                startDate: dateRegion.dateAtStartOf(.month).date,
                endDate: dateRegion.dateAtEndOf(.month).date)
        case .decade:
            return extractDatePeriod(timeUnit: .year)
        }
    }

    var appTimeFormat: Int {
        return Int(self.timeIntervalSince1970)
    }
}

extension DateInRegion {
    func dateAtStartOfDecade(distance: Int = 0) -> DateInRegion {
        let currentYear = self.dateAtStartOf(.day).year - 10 * distance
        return DateInRegion(year: currentYear - (currentYear % 10), month: 1, day: 1)
    }

    func dateAtEndOfDecade(distance: Int = 0) -> DateInRegion {
        let currentYear = self.dateAtStartOf(.day).year - 10 * distance
        return DateInRegion(year: currentYear + (9 - currentYear % 10), month: 12, day: 1).dateAtEndOf(.month)
    }
}

extension String {
    var appDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(Double(self) ?? 0))
    }
}
