//
//  StackedBarValueFormatter.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Charts

final class StackedBarValueFormatter: IValueFormatter {
    private var lastEntry: ChartDataEntry? = nil
    private var iteratedStackIndex = 1
    private let isHorizontal: Bool
    private var entryMap = [BarChartDataEntry: Int]()
    
    init(isHorizontal: Bool) {
        self.isHorizontal = isHorizontal
    }

    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        guard let e = entry as? BarChartDataEntry,
            let values = e.yValues else {
            assert(false, "entry is not a BarChartDataEntry or empty yValues")
            return ""
        }
        
        if var value = entryMap[e] {
            value += 1
            entryMap[e] = value
        } else {
            entryMap[e] = 1
        }
        
        let currentIndex = entryMap[e]!
        
        if !isHorizontal {
            print("\(currentIndex) - \(values) - \(String(Int(values.reduce(0, +))))")
        }

        if isHorizontal {
            var rightZeroCount = 0
            for v in values.reversed() {
                if v == 0 {
                    rightZeroCount += 1
                } else {
                    break
                }
            }
            
            if currentIndex == values.count * 3 - rightZeroCount {
                return String(Int(values.reduce(0, +)))
            }
        } else {
            if currentIndex == values.count * 3 - 1 {
                return String(Int(values.reduce(0, +)))
            }
        }

        return ""
    }
}
