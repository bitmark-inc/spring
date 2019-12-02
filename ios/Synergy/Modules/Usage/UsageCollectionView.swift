//
//  UsageCollectionView.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.row {
        case 0:
            return collectionView.dequeueReusableCell(withClass: UsageBadgeCollectionViewCell.self, for: indexPath)
        case 1:
            let cell = collectionView.dequeueReusableCell(withClass: UsageHeadingCollectionViewCell.self, for: indexPath)
            cell.bindData(countText: "24 POSTS", actionDescriptionText: "you made")
            return cell
        case 2:
            return collectionView.dequeueReusableCell(withClass: FilterTypeCollectionViewCell.self, for: indexPath)
        case 3:
            return collectionView.dequeueReusableCell(withClass: FilterDayCollectionViewCell.self, for: indexPath)
        case 4:
            return collectionView.dequeueReusableCell(withClass: FilterFriendsCollectionViewCell.self, for: indexPath)
        case 5:
            return collectionView.dequeueReusableCell(withClass: FilterPlacesCollectionViewCell.self, for: indexPath)
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
                flex.addItem(countLabel)
                flex.addItem(actionDescriptionLabel).marginLeft(4)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func bindData(countText: String, actionDescriptionText: String) {
        countLabel.text = countText
        actionDescriptionLabel.text = actionDescriptionText
    }
}

class FilterTypeCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).width(300).height(300)
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
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = true
        
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true

        bindData()
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData() {
        headingLabel.text = "BY TYPE"
        
        let set1 = BarChartDataSet(entries: [
            BarChartDataEntry(x: 0, y: 2.0),
            BarChartDataEntry(x: 1, y: 9.0),
            BarChartDataEntry(x: 2, y: 8.0),
            BarChartDataEntry(x: 3, y: 2.0),
            BarChartDataEntry(x: 4, y: 3.0)
        ])
        set1.colors = [
            UIColor(hexString: "#BBEAA6")!,
            UIColor(hexString: "#E3C878")!,
            UIColor(hexString: "#ED9A73")!,
            UIColor(hexString: "#E688A1")!,
            UIColor(hexString: "#81CFFA")!
        ]
        
        let data = BarChartData(dataSets: [set1])
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        data.barWidth = 0.4
        data.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Posts", "Photos", "Stories", "Videos", "Links"])
        chartView.xAxis.labelCount = 5
    }
}

class FilterDayCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = BarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).marginBottom(10).width(300).height(300)
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
        data.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
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
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).width(300).height(300)
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

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true

        bindData()
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData() {
        headingLabel.text = "BY FRIENDS TAGGED"
        
        let set1 = BarChartDataSet(entries: [
            BarChartDataEntry(x: 0, yValues: [2, 2]),
            BarChartDataEntry(x: 1, yValues: [2, 0]),
            BarChartDataEntry(x: 2, yValues: [1, 0])
        ], label: "")
        set1.colors = [
            UIColor(hexString: "#E3C878")!,
            UIColor(hexString: "#ED9A73")!
        ]
        
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        data.barWidth = 0.4
        data.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Phil Lin", "Hongtai CrossFit", "Mars Chen"])
        chartView.xAxis.labelCount = 3
        chartView.legend.enabled = false
    }
}

class FilterPlacesCollectionViewCell: CollectionViewCell {
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 14))
    private let chartView = HorizontalBarChartView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.flex.direction(.column).define { (flex) in
            flex.paddingLeft(18).paddingRight(18)
            flex.alignItems(.start)
            flex.addItem(headingLabel)
            flex.addItem(chartView).marginLeft(19).marginTop(10).width(300).height(300)
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

        let l = chartView.legend
        l.enabled = false
        chartView.fitBars = true

        bindData()
    }
       
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bindData() {
        headingLabel.text = "BY PLACES TAGGED"
        
        let set1 = BarChartDataSet(entries: [
            BarChartDataEntry(x: 0, yValues: [2, 6]),
            BarChartDataEntry(x: 1, yValues: [2, 2])
        ], label: "")
        set1.colors = [
            UIColor(hexString: "#E3C878")!,
            UIColor(hexString: "#ED9A73")!
        ]
        
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:10)!)
        data.barWidth = 0.4
        data.setValueFormatter(DefaultValueFormatter(decimals: 0))
        
        chartView.data = data
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Hongtai CrossFit", "Saffron 46"])
        chartView.xAxis.labelCount = 2
        chartView.legend.enabled = false
    }
}
