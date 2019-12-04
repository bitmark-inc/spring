//
//  InsightCollectionView.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Charts

class InsightCollectionView: CollectionView {
    private let disposeBag = DisposeBag()
    var postListNavigateHandler: ((FilterScope) -> Void)?
    var timeUnit: TimeUnit = .week {
        didSet {
            self.reloadData { [unowned self] in
                self.setContentOffset(.zero, animated: true)
            }
        }
    }
    var startTime: Date = Date() {
        didSet {
            self.reloadData { [unowned self] in
                self.setContentOffset(.zero, animated: true)
            }
        }
    }
    
    override init() {
        super.init()
        
        self.dataSource = self
        self.register(cellWithClass: InsightBadgeCollectionViewCell.self)
        self.register(cellWithClass: InsightHeadingCollectionViewCell.self)
        self.register(cellWithClass: InsightFilterTypeCollectionViewCell.self)
        self.register(cellWithClass: InsightFilterDayCollectionViewCell.self)
        self.register(cellWithClass: InsightFilterPlacesCollectionViewCell.self)
        
        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension InsightCollectionView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 3
        case 3:
            return 4
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let c = collectionView as? InsightCollectionView else {
            assert(false, "collectionView is not InsightCollectionView")
        }
        
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return collectionView.dequeueReusableCell(withClass: InsightBadgeCollectionViewCell.self, for: indexPath)
        case (1, 0):
            let cell = collectionView.dequeueReusableCell(withClass: InsightHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "14 AD INTERESTS", actionDescriptionText: "tracked by Facebook")
            return cell
        case (1, 1):
            let cell = collectionView.dequeueReusableCell(withClass: InsightFilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .posts
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
            cell.bindData(title: "BY TYPE",
                          data: [("Entertainment", 1),
                                   ("Fitness & Wellness", 5),
                                   ("Food & Drink", 4),
                                   ("Hobbies & Activities", 1),
                                   ("Shopping & Fashion", 2)])
            cell.postListNavigateHandler = c.postListNavigateHandler
            return cell
        case (1, 2):
            return collectionView.dequeueReusableCell(withClass: InsightFilterDayCollectionViewCell.self, for: indexPath)
        case (2, 0):
            let cell = collectionView.dequeueReusableCell(withClass: InsightHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "5 ADVERTISERS", actionDescriptionText: "collected data about you")
            return cell
        case (2, 1):
            let cell = collectionView.dequeueReusableCell(withClass: InsightFilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .reactions
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
            cell.bindData(title: "BY TYPE",
            data: [("Entertainment", 1),
                     ("Fitness & Wellness", 5),
                     ("Food & Drink", 4),
                     ("Hobbies & Activities", 1),
                     ("Shopping & Fashion", 2)])
            return cell
        case (2, 2):
            return collectionView.dequeueReusableCell(withClass: InsightFilterDayCollectionViewCell.self, for: indexPath)
        case (3, 0):
            let cell = collectionView.dequeueReusableCell(withClass: InsightHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "35 LOCATIONS", actionDescriptionText: "tracked by Facebook")
            return cell
        case (3, 1):
            let cell = collectionView.dequeueReusableCell(withClass: InsightFilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .message
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
            cell.bindData(title: "BY AREA",
                          data: [("Taoyuan, Taiwan", 1),
                                 ("Taipei City, Taiwan", 5),
                                 ("New Taipei City, Taiwan", 4),
                                 ("Narita, Japan", 1),
                                 ("San Francisco, California, USA", 2)])
            return cell
        case (3, 2):
            let cell = collectionView.dequeueReusableCell(withClass: InsightFilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .message
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
            cell.bindData(title: "BY TYPE",
                          data: [("Shopping Center", 1),
                                 ("Restaurant", 5),
                                 ("Gym", 4),
                                 ("Park", 1),
                                 ("Airport", 2)])
            return cell
        case (3, 3):
            return collectionView.dequeueReusableCell(withClass: InsightFilterDayCollectionViewCell.self, for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withClass: InsightHeadingCollectionViewCell.self, for: indexPath)
        }
            
    }
}

extension Reactive where Base: InsightCollectionView {
    
    /// Reactive wrapper for `timeUnit` property.
    var timeUnit: Binder<TimeUnit> {
        return Binder(self.base) { view, attr in
            view.timeUnit = attr
        }
    }
    
    /// Reactive wrapper for `timeUnit` property.
    var startTime: Binder<Date> {
        return Binder(self.base) { view, attr in
            view.startTime = attr
        }
    }
}

class InsightHeadingCollectionViewCell: CollectionViewCell {
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
                flex.addItem(countLabel)
                flex.addItem(actionDescriptionLabel).marginLeft(4)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        invalidateIntrinsicContentSize()
    }
    
    func bindData(countText: String, actionDescriptionText: String) {
        countLabel.text = countText
        actionDescriptionLabel.text = actionDescriptionText
        countLabel.flex.markDirty()
        actionDescriptionLabel.flex.markDirty()
    }
}

class InsightFilterTypeCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    var postListNavigateHandler: ((FilterScope) -> Void)?
    private var entries = [BarChartDataEntry]()
    var section: Section = .posts
    var timeUnit: TimeUnit = .week
    var startTime: Date = Date()
    
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
        chartView.highlightPerTapEnabled = true
                
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

    func bindData(title: String, data: [(String, Double)]) {
        headingLabel.text = title
        
        var values = [String]()
        entries = [BarChartDataEntry]()
        
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

class InsightFilterDayCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    let chartView = BarChartView()
    
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

class InsightFilterPlacesCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    let chartView = HorizontalBarChartView()
    
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
