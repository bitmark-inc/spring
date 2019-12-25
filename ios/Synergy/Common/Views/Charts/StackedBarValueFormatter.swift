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

    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        guard let e = entry as? BarChartDataEntry,
            var values = e.yValues else {
            assert(false, "entry is not a BarChartDataEntry or empty yValues")
            return ""
        }
        // The library calls to this func twice,
        // one doesn't care type of data set
        // one after that, if the data set is stacked, then call this function again to recalculate.
        if value == entry.y && !values.contains(value) {
            // Find out if it's first place.
            return ""
        }

        // Trim all 0 values on right hand side of the array as
        // bar chart label doesn't display them.
        while true {
            if values.last == 0 {
                values.removeLast()
            } else {
                break
            }
        }

        if lastEntry != entry {
            lastEntry = entry
            iteratedStackIndex = 1
        }

        defer {
            iteratedStackIndex += 1
        }

        if iteratedStackIndex < values.count {
            return ""
        }

        return String(Int(values.reduce(0, +)))
    }
}
