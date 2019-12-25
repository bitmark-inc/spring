//
//  GraphDataConverter.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/18/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import SwiftDate

class GraphDataConverter {

    // MARK: - Properties
    static let formatInDay = "yyyy-MM-dd"
    static let showingLimit = 5

    // MARK: - Handlers
    static func getDataGroupByType(with graphData: GraphData, in section: Section) -> [(String, Double)] {

        return getOrderedKeys(in: section)
            .map { (key) in
                (key,
                 graphData.data[key] ?? 0)
            }
    }

    static func getDataGroupByDay(with graphDatas: [GraphData], timeUnit: TimeUnit, startDate: Date, in section: Section) -> [Date: (String, [Double])] {
        var dayGraphDatas: [Date: (String, [Double])] = [:]

        let orderedKeys = getOrderedKeys(in: section)

        for index in (0..<numberOfBars(for: timeUnit)) {
            let indexDate = startDate + timeUnit.barDateComponents(distance: index)
            dayGraphDatas[indexDate] = (timeUnit.shortenDayName(for: indexDate), [Double](repeating: 0.0, count: orderedKeys.count))
        }

        graphDatas.filter { $0.name != nil }
            .forEach { (graphData) in
                let date = graphData.name!.appDate
                let numberData = orderedKeys.map { graphData.data[$0] ?? 0 }
                dayGraphDatas[date] = (timeUnit.shortenDayName(for: date), numberData)
        }

        return dayGraphDatas
    }

    static func getDataGroupByNameValue(with graphDatas: [GraphData], in section: Section) -> [(names: [String], sumData: Double, data: [Double])] {
        let orderedKeys = getOrderedKeys(in: section)
        var nameGraphDatas: [(names: [String], sumData: Double, data: [Double])] = graphDatas.map { graphData in
            let name = [graphData.name ?? ""]
            let numberData = orderedKeys.map { graphData.data[$0] ?? 0 }

            return (names: name, sumData: numberData.sum(), data: numberData)
        }

        nameGraphDatas.sort(by: { $0.sumData > $1.sumData })

        let numberOfNames = nameGraphDatas.count
        var showingNameGraphDatas: [(names: [String], sumData: Double, data: [Double])] = []

        if numberOfNames > showingLimit {
            showingNameGraphDatas = Array(nameGraphDatas[..<showingLimit])
            let hiddenNameGraphDatas = nameGraphDatas[showingLimit...]

            let otherNames = hiddenNameGraphDatas.reduce([]) { $0 + $1.names }
            let otherSumDatas = hiddenNameGraphDatas.reduce(0.0) { $0 + $1.sumData }
            let otherDatas = hiddenNameGraphDatas.reduce([Double](repeating: 0.0, count: orderedKeys.count)) { (result, nameGraphData) in
                let numberData = nameGraphData.data
                return result.enumerated().map { $1 + numberData[$0] }
            }
            showingNameGraphDatas.append((names: otherNames, sumData: otherSumDatas, data: otherDatas))
        } else {
            showingNameGraphDatas = nameGraphDatas
        }

        return showingNameGraphDatas
    }

    fileprivate static func getOrderedKeys(in section: Section) -> [String] {
        switch section {
        case .posts:
            return PostType.orderedKey
        case .reactions:
            return ReactionType.orderedKey
        default:
            return []
        }
    }

    fileprivate static func numberOfBars(for timeUnit: TimeUnit) -> Int {
        switch timeUnit {
        case .week:     return 7
        case .year:     return 12
        case .decade:   return 10
        }
    }
}

enum PostType: String {
    case update, media, story, link

    static var orderedList: [PostType] {
        return [.update, .media, .story, .link]
    }

    static var barChartColors: [UIColor] {
        return [UIColor(hexString: "#BBEAA6")!,
                UIColor(hexString: "#E3C878")!,
                UIColor(hexString: "#ED9A73")!,
                UIColor(hexString: "#81CFFA")!
        ]
    }

    static var orderedKey: [String] {
        orderedList.map { $0.keyInGroups }
    }

    var keyInGroups: String {
        return self.rawValue
    }
}

enum ReactionType: String {
    case like, love, haha, wow, sad, angry

    static var orderedList: [ReactionType] {
        return [.like, .love, .haha, .wow, .sad, .angry]
    }

    static var barChartColors: [UIColor] {
        return [UIColor(hexString: "#BBEAA6")!,
                UIColor(hexString: "#E3C878")!,
                UIColor(hexString: "#ED9A73")!,
                UIColor(hexString: "#81CFFA")!
        ]
    }

    static var orderedKey: [String] {
        orderedList.map { $0.keyInGroups }
    }

    var keyInGroups: String {
        switch self {
        case .sad:      return "sorry"
        case .angry:    return "anger"
        default:        return self.rawValue
        }
    }
}

struct MoodType {
    let value: Int

    var moodImage: UIImage? {
        switch value {
        case 0:     return R.image.mood0()
        case 1,2:   return R.image.mood1()
        case 3,4:   return R.image.mood2()
        case 5,6:   return R.image.mood3()
        case 7,8:   return R.image.mood4()
        case 9,10:  return R.image.mood5()
        default:
            return nil
        }
    }

    var moodBarImage: UIImage? {
        switch value {
        case 0:     return R.image.moodBar0()
        case 1:     return R.image.moodBar1()
        case 2:     return R.image.moodBar2()
        case 3:     return R.image.moodBar3()
        case 4:     return R.image.moodBar4()
        case 5:     return R.image.moodBar5()
        case 6:     return R.image.moodBar6()
        case 7:     return R.image.moodBar7()
        case 8:     return R.image.moodBar8()
        case 9:     return R.image.moodBar9()
        case 10:    return R.image.moodBar10()
        default:
            return nil
        }
    }
}
