//
//  AbbreviatedValueFormatter.swift
//  Synergy
//
//  Created by Anh Nguyen on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Charts

final class AbbreviatedValueFormatter: NSObject, IValueFormatter
{
    func stringForValue(_ value: Double,
                             entry: ChartDataEntry,
                             dataSetIndex: Int,
                             viewPortHandler: ViewPortHandler?) -> String
    {
        return Int(value).abbreviated
    }
}
