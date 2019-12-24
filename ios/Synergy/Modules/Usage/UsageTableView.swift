//
//  UsageTableView.swift
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

class UsageTableView: TableView {

    // MARK: - Properties
    var postListNavigateHandler: ((FilterScope) -> Void)?
    var accountNavigationHandler: (() -> Void)?
    var timeUnit: TimeUnit = .week {
        didSet {
            self.reloadSections(IndexSet(integersIn: 2...5), with: .automatic)
        }
    }
    var startTime: Date = Date() {
        didSet {
            self.reloadSections(IndexSet(integersIn: 2...5), with: .automatic)
        }
    }

    var usage: [String: Any] = [:]

    // MARK: - Inits
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)

        self.dataSource = self
        self.register(cellWithClass: HeadingTableViewCell.self)
        self.register(cellWithClass: TimeFilterTableViewCell.self)
        self.register(cellWithClass: UsageBadgeTableViewCell.self)
        self.register(cellWithClass: UsageHeadingTableViewCell.self)
        self.register(cellWithClass: FilterTypeTableViewCell.self)
        self.register(cellWithClass: FilterDayTableViewCell.self)
        self.register(cellWithClass: FilterFriendsTableViewCell.self)
        self.register(cellWithClass: FilterPlacesTableViewCell.self)

        themeService.rx
            .bind({ $0.background }, to: rx.backgroundColor)
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - UITableViewDataSource
extension UsageTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 1
        case 3:
            return 5
        case 4:
            return 4
        case 5:
            return 3
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         guard let c = tableView as? UsageTableView else {
             assert(false, "tableView is not UsageTableView")
             return UITableViewCell()
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
            let cell = tableView.dequeueReusableCell(withClass: HeadingTableViewCell.self, for: indexPath)
            cell.setHeading(title: R.string.localizable.usage().localizedUppercase, color:  UIColor(hexString: "#932C19"))
            cell.subTitle = R.string.localizable.howyouusefacebooK()
            cell.accountButton.rx.tap.bind { [weak self] in
                self?.accountNavigationHandler?()
            }.disposed(by: disposeBag)
            return cell
         case (1, _):
            let cell = tableView.dequeueReusableCell(withClass: TimeFilterTableViewCell.self, for: indexPath)
            cell.filterChangeSubject
                .subscribeOn(MainScheduler())
                .subscribe(onNext: { [weak self] (timeUnit) in
                    self?.timeUnit = timeUnit
                })
                .disposed(by: disposeBag)
            return cell
         case (2, _):
             let cell = tableView.dequeueReusableCell(withClass: UsageBadgeTableViewCell.self, for: indexPath)
             cell.timeUnit = c.timeUnit
             return cell
         case (3, 0):
             let cell = tableView.dequeueReusableCell(withClass: UsageHeadingTableViewCell.self, for: indexPath)
             let numberOfPosts = Constant.numberOfPosts(timeUnit: timeUnit)
             cell.bindData(countText: "\(numberOfPosts) POSTS", actionDescriptionText: "you made")
             return cell
         case (3, 1):
             let cell = tableView.dequeueReusableCell(withClass: FilterTypeTableViewCell.self, for: indexPath)
             cell.section = .posts
             cell.timeUnit = c.timeUnit
             cell.startTime = c.startTime
             cell.selectionEnabled = true

             let usageByType = usage[GroupKey.type.rawValue]!
             let data = usageByType.first!["data"] as! [String: [Any]]
             let keys = data["keys"] as! [String]
             let values = data["values"] as! [Int]

             let stats = (0..<keys.count).map { (keys[$0], Double(values[$0])) }
             cell.bindData(data: stats)
             cell.postListNavigateHandler = c.postListNavigateHandler
             return cell
         case (3, 2):
             let cell = tableView.dequeueReusableCell(withClass: FilterDayTableViewCell.self, for: indexPath)
             cell.postListNavigateHandler = c.postListNavigateHandler
             return cell
         case (3, 3):
             let cell = tableView.dequeueReusableCell(withClass: FilterFriendsTableViewCell.self, for: indexPath)
             cell.timeUnit = timeUnit
             cell.postListNavigateHandler = c.postListNavigateHandler
             let usageByFriends = usage[GroupKey.friend.rawValue]!
             let stats = usageByFriends.map { (usageByFriend) -> (String, [Double]) in
                 let data = usageByFriend["data"] as! [String: [Any]]
                 let values = data["values"] as! [Int]

                 return (usageByFriend["name"] as! String, values.map { Double($0) })
             }

             cell.bindData(data: stats)
             return cell
         case (3, 4):
             let cell = tableView.dequeueReusableCell(withClass: FilterPlacesTableViewCell.self, for: indexPath)
             cell.timeUnit = timeUnit
             cell.postListNavigateHandler = c.postListNavigateHandler
             let usageByPlaces = usage[GroupKey.place.rawValue]!
             let stats = usageByPlaces.map { (usageByPlace) -> (String, [Double]) in
                 let data = usageByPlace["data"] as! [String: [Any]]
                 let values = data["values"] as! [Int]

                 return (usageByPlace["name"] as! String, values.map { Double($0) })
             }

             cell.bindData(data: stats)
             return cell
         case (4, 0):
             let cell = tableView.dequeueReusableCell(withClass: UsageHeadingTableViewCell.self, for: indexPath)
             cell.bindData(countText: "100 REACTIONS", actionDescriptionText: "you gave")
             return cell
         case (4, 1):
             let cell = tableView.dequeueReusableCell(withClass: FilterTypeTableViewCell.self, for: indexPath)
             cell.section = .reactions
             cell.timeUnit = c.timeUnit
             cell.startTime = c.startTime
             cell.selectionEnabled = false
             cell.bindData(data: [("Like", 34), ("Love", 40), ("Haha", 19), ("Wow", 5), ("Sad", 2), ("Angry", 0)])
             return cell
         case (4, 2):
             return tableView.dequeueReusableCell(withClass: FilterDayTableViewCell.self, for: indexPath)
         case (4, 3):
             let cell = tableView.dequeueReusableCell(withClass: FilterFriendsTableViewCell.self, for: indexPath)
             cell.bindData(data: [("Phillip Botha", [1,4,2]), ("Jeep Ampol", [3,4,2]), ("Hezali Nel", [1,4,1])])
             return cell
         case (5, 0):
             let cell = tableView.dequeueReusableCell(withClass: UsageHeadingTableViewCell.self, for: indexPath)
             cell.bindData(countText: "341 MESSAGES", actionDescriptionText: "you sent or received")
             return cell
         case (5, 1):
             let cell = tableView.dequeueReusableCell(withClass: FilterTypeTableViewCell.self, for: indexPath)
             cell.section = .message
             cell.timeUnit = c.timeUnit
             cell.startTime = c.startTime
             cell.selectionEnabled = false
             cell.bindData(data: [("TPE Pride 2019", 182), ("Beven Lan", 43), ("Danny & Phil", 39), ("Kevin Y", 25), ("Jeffy Davenport", 23), ("Others", 29)])
             return cell
         case (5, 2):
             return tableView.dequeueReusableCell(withClass: FilterDayTableViewCell.self, for: indexPath)
         default:
             return tableView.dequeueReusableCell(withClass: UsageHeadingTableViewCell.self, for: indexPath)
         }

    }
}

extension Reactive where Base: UsageTableView {

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

class TimeFilterTableViewCell: TableViewCell {
    private let filterSegment = FilterSegment(elements: ["WEEK".localized(),
                                                          "YEAR".localized(),
                                                          "DECADE".localized()
    ])
    
    private let previousPeriodButton: Button = {
        let btn = Button()
        btn.setImage(R.image.previous_period()!, for: .normal)
        return btn
    }()
    
    private let nextPeriodButton: Button = {
        let btn = Button()
        btn.setImage(R.image.next_period()!, for: .normal)
        return btn
    }()
    
    private lazy var periodNameLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 18))
    private lazy var periodDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))
    
    let filterChangeSubject = PublishSubject<TimeUnit>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        periodNameLabel.text = "THIS WEEK"
        periodDescriptionLabel.text = "2019 Dec 1st - Dec 7th"
        periodNameLabel.textAlignment = .center
        periodDescriptionLabel.textAlignment = .center
        
        contentView.flex.direction(.column).define { (flex) in
            flex.paddingTop(13).paddingBottom(30)
            flex.addItem(filterSegment).marginLeft(18).marginRight(18).height(40)
            flex.addItem().direction(.row).define { (flex) in
                flex.marginTop(18).marginLeft(18).marginRight(18).height(19)
                flex.justifyContent(.center)
                flex.alignItems(.stretch)
                flex.addItem(previousPeriodButton)
                flex.addItem(periodNameLabel).grow(1)
                flex.addItem(nextPeriodButton)
            }
            flex.addItem(periodDescriptionLabel).marginTop(9).height(10).alignSelf(.stretch)
        }
        
        bindData()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        invalidateIntrinsicContentSize()
    }
    
    private func bindData() {
        let d = filterSegment.rx.selectedIndex.share(replay: 1, scope: .forever)
        d.map { (index) -> TimeUnit in
            switch index {
            case 0:
                return .week
            case 1:
                return .year
            case 2:
                return .decade
            default:
                return .week
            }
            }.bind(to: filterChangeSubject)
            .disposed(by: disposeBag)
        
        d.map { (index) -> String in
            switch index {
            case 0:
                return "THIS WEEK"
            case 1:
                return "THIS YEAR"
            case 2:
                return "THIS DECADE"
            default:
                return ""
            }
        }.bind(to: periodNameLabel.rx.text)
        .disposed(by: disposeBag)
        
        d.map { (index) -> String in
            switch index {
            case 0:
                return "2019 Dec 1st - Dec 7th"
            case 1:
                return "2019 Jan 1st - Dec 31st"
            case 2:
                return "2010 - 2019"
            default:
                return ""
            }
        }.bind(to: periodDescriptionLabel.rx.text)
        .disposed(by: disposeBag)
    }
}

class UsageHeadingTableViewCell: TableViewCell {

    private let countLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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

class FilterTypeTableViewCell: TableViewCell {

    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    private let chartView = HorizontalBarChartView()
    var postListNavigateHandler: ((FilterScope) -> Void)?
    private var entries = [BarChartDataEntry]()
    var section: Section = .posts
    var timeUnit: TimeUnit = .week
    var startTime: Date = Date()
    var selectionEnabled = true {
        didSet {
            chartView.highlightPerTapEnabled = selectionEnabled
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
        chartView.delegate = self

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        xAxis.labelFont = R.font.atlasGroteskLight(size: 12)!

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
        barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
        barData.barWidth = 0.15
        barData.setValueFormatter(DefaultValueFormatter(decimals: 0))

        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
        chartView.xAxis.labelCount = 5

        chartView.flex.height(CGFloat(data.count * 35 + 10))

        self.layout()
    }
}

extension FilterTypeTableViewCell: ChartViewDelegate {
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

//        let filterScope: FilterScope = (
//            usageScope: (
//                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
//            ),
//            filterBy: .type,
//            filterValue: filterValue
//        )

//        self.postListNavigateHandler?(filterScope)

        chartView.highlightValues(nil)
    }
}

class FilterDayTableViewCell: TableViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    var postListNavigateHandler: ((FilterScope) -> Void)?
    let chartView = BarChartView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
        xAxis.labelFont = R.font.atlasGroteskLight(size: 12)!

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
        data.setValueFont(R.font.atlasGroteskLight(size: 12)!)
        data.barWidth = 0.4
        data.setValueFormatter(StackedBarValueFormatter())

        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["S", "M", "T", "W", "T", "F", "S"])
        chartView.xAxis.labelCount = 7
        chartView.legend.enabled = false
    }
}

extension FilterDayTableViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let filterValue = Constant.PostType.photo
        let section: Section = .posts
        let timeUnit: TimeUnit = .week
        let startTime: Date = Date()
//        let filterScope: FilterScope = (
//            usageScope: (
//                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
//            ),
//            filterBy: .type,
//            filterValue: filterValue
//        )

//        self.postListNavigateHandler?(filterScope)

        chartView.highlightValues(nil)
    }
}

class FilterFriendsTableViewCell: TableViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    var postListNavigateHandler: ((FilterScope) -> Void)?
    let chartView = HorizontalBarChartView()
    var friends = [String]()
    var timeUnit: TimeUnit = .week

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
        xAxis.labelFont = R.font.atlasGroteskLight(size: 12)!

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
        barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
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

extension FilterFriendsTableViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let friend = friends[Int(entry.x)]
        let section: Section = .posts

        let startTime: Date = Date()
//        let filterScope: FilterScope = (
//            usageScope: (
//                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
//            ),
//            filterBy: .friend,
//            filterValue: friend
//        )

//        self.postListNavigateHandler?(filterScope)

        chartView.highlightValues(nil)
    }
}

class FilterPlacesTableViewCell: TableViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    let chartView = HorizontalBarChartView()
    var postListNavigateHandler: ((FilterScope) -> Void)?
    var places = [String]()
    var timeUnit: TimeUnit = .week

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

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
        xAxis.labelFont = R.font.atlasGroteskLight(size: 12)!

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

        places = [String]()
        var entries = [BarChartDataEntry]()
        var i: Double = 0
        for (k,v) in data.reversed() {
            places.append(k)
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
        barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
        barData.barWidth = 0.15
        barData.setValueFormatter(StackedBarValueFormatter())

        chartView.data = barData
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: places)
        chartView.xAxis.labelCount = data.count
        chartView.legend.enabled = false

        chartView.flex.height(CGFloat(data.count * 50))

        layout()
    }
}

extension FilterPlacesTableViewCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let place = places[Int(entry.x)]
        let section: Section = .posts
        let startTime: Date = Date()
//        let filterScope: FilterScope = (
//            usageScope: (
//                sectionName: section.rawValue, timeUnit: timeUnit.rawValue, date: startTime
//            ),
//            filterBy: .place,
//            filterValue: place
//        )

//        self.postListNavigateHandler?(filterScope)

        chartView.highlightValues(nil)
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
