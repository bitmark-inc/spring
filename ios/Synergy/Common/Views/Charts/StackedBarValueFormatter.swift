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
                return Int(values.reduce(0, +)).abbreviated
            }
        } else {
            let zeroCount = values.filter { $0 == 0 }.count
            var rightDeduct = 0
            if zeroCount == values.count {
                rightDeduct = 0
            } else if zeroCount == 0 {
                rightDeduct = 1
            } else {
                rightDeduct = zeroCount
            }
            if currentIndex == values.count * 3 - rightDeduct {
                return Int(values.reduce(0, +)).abbreviated
            }
        }

        return ""
    }
}

extension Int {
    var abbreviated: String {
        let abbrev = "KMBTPE"
        return abbrev.enumerated().reversed().reduce(nil as String?) { accum, tuple in
            let factor = Double(self) / pow(10, Double(tuple.0 + 1) * 3)
            let format = (factor.truncatingRemainder(dividingBy: 1)  == 0 ? "%.0f%@" : "%.1f%@")
            return accum ?? (factor > 1 ? String(format: format, factor, String(tuple.1)) : nil)
            } ?? String(self)
    }
}
