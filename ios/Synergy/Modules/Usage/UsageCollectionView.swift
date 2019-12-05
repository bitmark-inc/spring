//
//  UsageCollectionView.swift
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

class UsageCollectionView: CollectionView {
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

    var usage: [String: Any] = [:]
    
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

        guard let c = collectionView as? UsageCollectionView else {
            assert(false, "collectionView is not UsageCollectionView")
            return UICollectionViewCell()
        }

        var usage: [String: [[String: Any]]]!

        switch timeUnit {
        case .week:
            usage = Constant.postWeekUsage()
        case .year:
            usage = Constant.postYearUsage()
        case .decade:
            usage = Constant.postDecadeUsage()
        }

        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return collectionView.dequeueReusableCell(withClass: UsageBadgeCollectionViewCell.self, for: indexPath)
        case (1, 0):
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            let numberOfPosts = Constant.numberOfPosts(timeUnit: timeUnit)
            cell.bindData(countText: "\(numberOfPosts) POSTS", actionDescriptionText: "you made")
            return cell
        case (1, 1):
            let cell = collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .posts
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime

            let usageByType = usage[GroupKey.type.rawValue]!
            let data = usageByType.first!["data"] as! [String: [Any]]
            let keys = data["keys"] as! [String]
            let values = data["values"] as! [Int]

            let stats = (0..<keys.count).map { (keys[$0], Double(values[$0])) }
            cell.bindData(data: stats)
            cell.postListNavigateHandler = c.postListNavigateHandler
            return cell
        case (1, 2):
            let cell = collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
            cell.postListNavigateHandler = c.postListNavigateHandler
            return cell
        case (1, 3):
            let cell = collectionView.dequeueReusableCell(withClass: FilterFriendsCollectionViewCell.self, for: indexPath)
            cell.postListNavigateHandler = c.postListNavigateHandler
            let usageByFriends = usage[GroupKey.friend.rawValue]!
            let stats = usageByFriends.map { (usageByFriend) -> (String, [Double]) in
                let data = usageByFriend["data"] as! [String: [Any]]
                let values = data["values"] as! [Int]

                return (usageByFriend["name"] as! String, values.map { Double($0) })
            }

            cell.bindData(data: stats)
            return cell
        case (1, 4):
            let cell = collectionView.dequeueReusableCell(withClass: FilterPlacesCollectionViewCell.self, for: indexPath)

            let usageByPlaces = usage[GroupKey.place.rawValue]!
            let stats = usageByPlaces.map { (usageByPlace) -> (String, [Double]) in
                let data = usageByPlace["data"] as! [String: [Any]]
                let values = data["values"] as! [Int]

                return (usageByPlace["name"] as! String, values.map { Double($0) })
            }

            cell.bindData(data: stats)
            return cell
        case (2, 0):
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "100 REACTIONS", actionDescriptionText: "you gave")
            return cell
        case (2, 1):
            let cell = collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
            cell.section = .reactions
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
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
            cell.section = .message
            cell.timeUnit = c.timeUnit
            cell.startTime = c.startTime
            cell.bindData(data: [("TPE Pride 2019", 182), ("Beven Lan", 43), ("Danny & Phil", 39), ("Kevin Y", 25), ("Jeffy Davenport", 23), ("Others", 29)])
            return cell
        case (3, 2):
            return collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
        default:
            return collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
        }
            
    }
}

extension Reactive where Base: UsageCollectionView {
    
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

    var usage: Binder<[String: Any]> {
        return Binder(self.base) { view, attr in
            view.usage = attr
        }
    }
}

class UsageHeadingCollectionViewCell: CollectionViewCell {
    private let countLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 10))
        
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
                flex.alignItems(.start)
                flex.padding(38, 18, 28, 18)
                flex.addItem(countLabel)
                flex.addItem(actionDescriptionLabel).marginLeft(7)
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

class FilterTypeCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 14))
    private let chartView = HorizontalBarChartView()
    var postListNavigateHandler: ((FilterScope) -> Void)?
    private var entries = [BarChartDataEntry]()
    var section: Section = .posts
    var timeUnit: TimeUnit = .week
    var startTime: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.justifyContent(.start)
            flex.alignItems(.stretch)
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(0, 20, 15, 0).height(200)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.delegate = self
                
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelFont = R.font.atlasGroteskThin(size: 12)!
        
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
        
        let xAxisRender = chartView.xAxisRenderer
        chartView.xAxisRenderer = CustomxAxisRender(viewPortHandler: xAxisRender.viewPortHandler,
                                                    xAxis: xAxis,
                                                    transformer: xAxisRender.transformer,
                                                    chart: chartView)
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData(data: [(String, Double)]) {
        headingLabel.text = "BY TYPE"
        
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
        ].reversed()
        
        let barData = BarChartData(dataSets: [set1])
        barData.setValueFont(R.font.atlasGroteskThin(size: 12)!)
        barData.barWidth = 0.15
        barData.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
        chartView.xAxis.labelCount = 5
        
        chartView.flex.height(CGFloat(data.count * 35 + 10))
        
        self.layout()
    }
}

extension FilterTypeCollectionViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        var filterValue = ""
        if section == .posts {
            let index = entries.firstIndex(of: entry as! BarChartDataEntry)
            switch index {
            case 0:
                filterValue = Constant.PostType.link
            case 1:
                filterValue = Constant.PostType.video
            case 2:
                filterValue = Constant.PostType.story
            case 3:
                filterValue = Constant.PostType.photo
            case 4:
                filterValue = Constant.PostType.update
            default:
                filterValue = Constant.PostType.update
            }
        }
        
        let filterScope: FilterScope = (
            usageScope: (
                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
            ),
            filterBy: .type,
            filterValue: filterValue
        )

        self.postListNavigateHandler?(filterScope)
        
        chartView.highlightValues(nil)
    }
}

class FilterDayCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 14))
    var postListNavigateHandler: ((FilterScope) -> Void)?
    let chartView = BarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.justifyContent(.start)
            flex.alignItems(.stretch)
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(0, 20, 15, 0).width(50%).height(220)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        
        chartView.maxVisibleCount = 60
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.delegate = self
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.granularity = 1
        xAxis.labelFont = R.font.atlasGroteskThin(size: 12)!
        
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
        ].reversed()
        
        let data = BarChartData(dataSet: set1)
        data.setValueFont(R.font.atlasGroteskThin(size: 12)!)
        data.barWidth = 0.4
        data.setValueFormatter(StackedBarValueFormatter())
        
        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["S", "M", "T", "W", "T", "F", "S"])
        chartView.xAxis.labelCount = 7
        chartView.legend.enabled = false
    }
}

extension FilterDayCollectionViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let filterValue = Constant.PostType.photo
        let section: Section = .posts
        let timeUnit: TimeUnit = .week
        let startTime: Date = Date()
        let filterScope: FilterScope = (
            usageScope: (
                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
            ),
            filterBy: .type,
            filterValue: filterValue
        )

        self.postListNavigateHandler?(filterScope)
        
        chartView.highlightValues(nil)
    }
}

class FilterFriendsCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 14))
    var postListNavigateHandler: ((FilterScope) -> Void)?
    let chartView = HorizontalBarChartView()
    var friends = [String]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.justifyContent(.start)
            flex.alignItems(.stretch)
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(0, 20, 15, 5).height(200)
        }
        
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.highlightPerTapEnabled = true
        chartView.delegate = self
                
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelFont = R.font.atlasGroteskThin(size: 12)!
        
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
        
        let xAxisRender = chartView.xAxisRenderer
        chartView.xAxisRenderer = CustomxAxisRender(viewPortHandler: xAxisRender.viewPortHandler,
                                                    xAxis: xAxis,
                                                    transformer: xAxisRender.transformer,
                                                    chart: chartView)
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData(data: [(String, [Double])]) {
        headingLabel.text = "BY FRIENDS TAGGED"
        
        friends = [String]()
        var entries = [BarChartDataEntry]()
        var i: Double = 0
        for (k,v) in data.reversed() {
            friends.append(k)
            entries.append(BarChartDataEntry(x: i, yValues: v))
            i += 1
        }
        
        let set1 = BarChartDataSet(entries: entries, label: "")
        set1.colors = [
            UIColor(hexString: "#81CFFA")!,
            UIColor(hexString: "#E688A1")!,
            UIColor(hexString: "#E3C878")!
        ].reversed()
        
        let barData = BarChartData(dataSet: set1)
        barData.setValueFont(R.font.atlasGroteskThin(size: 12)!)
        barData.barWidth = 0.15
        barData.setValueFormatter(StackedBarValueFormatter())
        
        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: friends)
        chartView.xAxis.labelCount = data.count
        chartView.legend.enabled = false
        
        chartView.flex.height(CGFloat(data.count * 50))
        
        layout()
    }
}

extension FilterFriendsCollectionViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let friend = friends[Int(entry.x)]
        let section: Section = .posts
        let timeUnit: TimeUnit = .week
        let startTime: Date = Date()
        let filterScope: FilterScope = (
            usageScope: (
                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
            ),
            filterBy: .friend,
            filterValue: friend
        )

        self.postListNavigateHandler?(filterScope)
        
        chartView.highlightValues(nil)
    }
}

class FilterPlacesCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskThin(size: 14))
    let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.justifyContent(.start)
            flex.alignItems(.stretch)
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(0, 20, 15, 5).height(200)
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
        xAxis.labelFont = R.font.atlasGroteskThin(size: 12)!
        
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
        
        let xAxisRender = chartView.xAxisRenderer
        chartView.xAxisRenderer = CustomxAxisRender(viewPortHandler: xAxisRender.viewPortHandler,
                                                    xAxis: xAxis,
                                                    transformer: xAxisRender.transformer,
                                                    chart: chartView)
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
        barData.setValueFont(R.font.atlasGroteskThin(size: 12)!)
        barData.barWidth = 0.15
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
            return ""
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
