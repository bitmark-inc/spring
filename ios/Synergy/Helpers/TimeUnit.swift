//
//  TimeUnit.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

enum TimeUnit: String {
    case week
    case year
    case decade

    var subDateComponent: Calendar.Component {
        switch self {
        case .week:     return .day
        case .year:     return .month
        case .decade:   return .year
        }
    }

    func barDateComponents(distance: Int) -> DateComponents {
        switch self {
        case .week: return DateComponents(day: distance)
        case .year: return DateComponents(month: distance)
        case .decade: return DateComponents(year: distance)
        }
    }

    func shortenDayName(for date: Date) -> String {
        switch self {
        case .week: return date.dayName(ofStyle: .oneLetter)
        case .year: return date.monthName(ofStyle: .oneLetter)
        case .decade: return date.toFormat("yy")
        }
    }

    func meaningTimeText(with distance: Int) -> String {
        return String.localizedStringWithFormat(
            "meaningWord.\(rawValue)".localized(),
            abs(Int32(distance)))
    }
}
