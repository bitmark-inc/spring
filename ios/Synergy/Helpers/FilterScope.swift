//
//  FilterScope.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/18/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct FilterScope {
    let date: Date
    let timeUnit: TimeUnit
    let section: Section
    let filterBy: GroupKey
    let filterValue: Any
}

struct UsageScope {
    let date: Date
    let timeUnit: TimeUnit
    let section: Section
}

struct DatePeriod {
    let startDate: Date
    let endDate: Date

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
}
