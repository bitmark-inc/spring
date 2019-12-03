//
//  UsageCollectionView.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout
import Charts

class UsageCollectionView: CollectionView {
    private let disposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        self.dataSource = self
        self.register(cellWithClass: UsageBadgeCollectionViewCell.self)
        self.register(cellWithClass: UsageHeadingCollectionViewCell.self)
        self.register(cellWithClass: FilterTypeCollectionViewCell.self)
        self.register(cellWithClass: FilterDayCollectionViewCell.self)
        self.register(cellWithClass: FilterFriendsCollectionViewCell.self)
        self.register(cellWithClass: FilterPlacesCollectionViewCell.self)
        
        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UsageCollectionView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 5
        case 2:
            return 4
        case 3:
            return 3
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return collectionView.dequeueReusableCell(withClass: UsageBadgeCollectionViewCell.self, for: indexPath)
        case (1, 0):
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "24 POSTS", actionDescriptionText: "you made")
            return cell
        case (1, 1):
            let cell = collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("Update", 2), ("Photos", 9), ("Stories", 8), ("Videos", 2), ("Links", 3)])
            return cell
        case (1, 2):
            return collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
        case (1, 3):
            let cell = collectionView.dequeueReusableCell(withClass: FilterFriendsCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("Phil Lin", [2,2]), ("Hongtai CrossFit", [2,0]), ("Mars Chen", [2,0])])
            return cell
        case (1, 4):
            let cell = collectionView.dequeueReusableCell(withClass: FilterPlacesCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("Hongtai CrossFit", [2,8]), ("Saffron 46", [2,2])])
            return cell
        case (2, 0):
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "100 REACTIONS", actionDescriptionText: "you gave")
            return cell
        case (2, 1):
            let cell = collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("Like", 34), ("Love", 40), ("Haha", 19), ("Wow", 5), ("Sad", 2), ("Angry", 0)])
            return cell
        case (2, 2):
            return collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
        case (2, 3):
            let cell = collectionView.dequeueReusableCell(withClass: FilterFriendsCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("Phillip Botha", [1,4,2]), ("Jeep Ampol", [0,4,2]), ("Hezali Nel", [1,4,0])])
            return cell
        case (3, 0):
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "341 MESSAGES", actionDescriptionText: "you sent or received")
            return cell
        case (3, 1):
            let cell = collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
            cell.bindData(data: [("TPE Pride 2019", 182), ("Beven Lan", 43), ("Danny & Phil", 39), ("Kevin Y", 25), ("Jeffy Davenport", 23), ("Others", 29)])
            return cell
        case (3, 2):
            return collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
        }
            
    }
}

class UsageHeadingCollectionViewCell: CollectionViewCell {
    private let countLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(33)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem().direction(.row).define { (flex) in
                flex.padding(38, 18, 28, 18)
                flex.alignItems(.start)
                flex.justifyContent(.start)
                flex.addItem(countLabel).grow(1)
                flex.addItem(actionDescriptionLabel).marginLeft(4).grow(1)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func bindData(countText: String, actionDescriptionText: String) {
        countLabel.text = countText
        actionDescriptionLabel.text = actionDescriptionText
        self.layout()
    }
}

class FilterTypeCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.justifyContent(.start)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).marginBottom(25).minWidth(90%).height(200)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = false
                
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false
        
        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawGridLinesEnabled = false

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData(data: [(String, Double)]) {
        headingLabel.text = "BY TYPE"
        
        var values = [String]()
        var entries = [BarChartDataEntry]()
        var i: Double = 0
        for (k,v) in data.reversed() {
            values.append(k)
            entries.append(BarChartDataEntry(x: i, y: v))
            i += 1
        }
        
        let set1 = BarChartDataSet(entries: entries)
        set1.colors = [
            UIColor(hexString: "#BBEAA6")!,
            UIColor(hexString: "#E3C878")!,
            UIColor(hexString: "#ED9A73")!,
            UIColor(hexString: "#E688A1")!,
            UIColor(hexString: "#81CFFA")!
        ]
        
        let barData = BarChartData(dataSets: [set1])
        barData.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        barData.barWidth = 0.4
        barData.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
        chartView.xAxis.labelCount = 5
        
        chartView.flex.height(CGFloat(data.count * 50))
        
        self.layout()
    }
}

class FilterDayCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = BarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.justifyContent(.start)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).marginBottom(25).minWidth(90%).height(300)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        
        chartView.maxVisibleCount = 60
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.granularity = 1
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        
        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false

        bindData()
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData() {
        headingLabel.text = "BY DAY"
        
        let set1 = BarChartDataSet(entries: [
            BarChartDataEntry(x: 0, yValues: [2, 3, 5, 8]),
            BarChartDataEntry(x: 1, yValues: [3, 4, 8, 8]),
            BarChartDataEntry(x: 2, yValues: [2, 3, 2, 2]),
            BarChartDataEntry(x: 3, yValues: [2, 1, 4, 2]),
            BarChartDataEntry(x: 4, yValues: [2, 5, 1, 2]),
            BarChartDataEntry(x: 5, yValues: [2, 0, 1, 6]),
            BarChartDataEntry(x: 6, yValues: [2, 2, 0, 2])
        ], label: "")
        set1.colors = [
            UIColor(hexString: "#BBEAA6")!,
            UIColor(hexString: "#E3C878")!,
            UIColor(hexString: "#ED9A73")!,
            UIColor(hexString: "#E688A1")!
        ]
        
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        data.barWidth = 0.4
        data.setValueFormatter(StackedBarValueFormatter())
        
        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["S", "M", "T", "W", "T", "F", "S"])
        chartView.xAxis.labelCount = 7
        chartView.legend.enabled = false
    }
}

class FilterFriendsCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.justifyContent(.start)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).marginBottom(25).minWidth(90%).height(200)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = false
                
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false
        
        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawGridLinesEnabled = false

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData(data: [(String, [Double])]) {
        headingLabel.text = "BY FRIENDS TAGGED"
        
        var values = [String]()
        var entries = [BarChartDataEntry]()
        var i: Double = 0
        for (k,v) in data.reversed() {
            values.append(k)
            entries.append(BarChartDataEntry(x: i, yValues: v))
            i += 1
        }
        
        let set1 = BarChartDataSet(entries: entries, label: "")
        set1.colors = [
            UIColor(hexString: "#81CFFA")!,
            UIColor(hexString: "#E688A1")!,
            UIColor(hexString: "#E3C878")!
        ]
        
        let barData = BarChartData(dataSet: set1)
        barData.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        barData.barWidth = 0.4
        barData.setValueFormatter(StackedBarValueFormatter())
        
        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
        chartView.xAxis.labelCount = data.count
        chartView.legend.enabled = false
        
        chartView.flex.height(CGFloat(data.count * 50))
        
        layout()
    }
}

class FilterPlacesCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.justifyContent(.start)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).marginBottom(25).minWidth(90%).height(200)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = false
                
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false
        
        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawGridLinesEnabled = false

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData(data: [(String, [Double])]) {
        headingLabel.text = "BY PLACES TAGGED"
        
        var values = [String]()
        var entries = [BarChartDataEntry]()
        var i: Double = 0
        for (k,v) in data.reversed() {
            values.append(k)
            entries.append(BarChartDataEntry(x: i, yValues: v))
            i += 1
        }
        
        let set1 = BarChartDataSet(entries: entries, label: "")
        set1.colors = [
            UIColor(hexString: "#81CFFA")!,
            UIColor(hexString: "#E688A1")!,
            UIColor(hexString: "#E3C878")!
        ]
        
        let barData = BarChartData(dataSet: set1)
        barData.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        barData.barWidth = 0.4
        barData.setValueFormatter(StackedBarValueFormatter())
        
        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
        chartView.xAxis.labelCount = data.count
        chartView.legend.enabled = false
        
        chartView.flex.height(CGFloat(data.count * 50))
        
        layout()
    }
}

final class StackedBarValueFormatter: IValueFormatter {
    private var lastEntry: ChartDataEntry? = nil
    private var iteratedStackIndex = 1
    
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        guard let e = entry as? BarChartDataEntry,
            var values = e.yValues else {
            assert(false, "entry is not a BarChartDataEntry or empty yValues")
        }
        
        values = values.filter { $0 != 0 }
        
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
        
        return String(Int(value))
    }
}
