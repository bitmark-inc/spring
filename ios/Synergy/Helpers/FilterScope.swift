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
}
