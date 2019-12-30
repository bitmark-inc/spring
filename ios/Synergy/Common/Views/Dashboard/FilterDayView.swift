//
//  FilterDayView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Charts

class FilterDayView: UIView {

    // MARK: - Properties
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    var chartView = BarChartView()
    let fixedBarWidth: CGFloat = 8

    var section: Section = .post
    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    weak var navigatorDelegate: NavigatorDelegate?
    var dataObserver: Disposable? // stop observing old-data
    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .marginTop(2).marginBottom(18)
            .define { (flex) in
                flex.addItem(headingLabel).marginLeft(18).marginRight(18)
                flex.addItem(chartView).margin(0, 20, 0, 5)
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
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: UsageViewController) {
        self.section = section

        container.thisViewModel.timeUnitRelay
            .subscribe(onNext: { [weak self] (timeUnit) in
                self?.updateFilterText(timeUnit: timeUnit)
            })
            .disposed(by: disposeBag)

        switch section {
        case .post:
            container.thisViewModel.realmPostUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.groupsPostUsageObservable
                            .map { $0.subPeriod }
                            .map { (graphDatas) -> [Date: (String, [Double])]? in
                                guard let graphDatas = graphDatas
                                    else {
                                        return nil
                                }

                                return GraphDataConverter.getDataGroupByDay(
                                    with: graphDatas,
                                    timeUnit: container.thisViewModel.timeUnitRelay.value,
                                    startDate: container.thisViewModel.dateRelay.value,
                                    in: .post)
                        }
                        .subscribe(onNext: { [weak self] (data) in
                            self?.fillData(with: data)
                        })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(with: nil)
                    }
                })
                .disposed(by: disposeBag)

        case .reaction:
            container.thisViewModel.realmReactionUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.groupsReactionUsageObservable
                            .map { $0.subPeriod }
                            .map { (graphDatas) -> [Date: (String, [Double])]? in
                                guard let graphDatas = graphDatas
                                    else {
                                        return nil
                                }

                                return GraphDataConverter.getDataGroupByDay(
                                    with: graphDatas,
                                    timeUnit: container.thisViewModel.timeUnitRelay.value,
                                    startDate: container.thisViewModel.dateRelay.value,
                                    in: .reaction)
                        }
                        .subscribe(onNext: { [weak self] (data) in
                            self?.fillData(with: data)
                        })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(with: nil)
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    fileprivate func fillData(with data: [Date: (String, [Double])]?) {
        if let data = data {
            var days = [String]()
            var entries = [BarChartDataEntry]()

            let dates = data.keys.sorted(by: <)
            for (index, date) in dates.enumerated() {
                guard let value = data[date] else { continue }
                days.append(value.0)
                entries.append(BarChartDataEntry(x: Double(index), yValues: value.1, data: date))
            }

            let barChartDataSet = BarChartDataSet(entries: entries)
            switch section {
            case .post:
                barChartDataSet.colors = PostType.barChartColors
            case .reaction:
                barChartDataSet.colors = ReactionType.barChartColors
            default:
                break
            }

            let data = BarChartData(dataSet: barChartDataSet)
            data.setValueFont(R.font.atlasGroteskLight(size: 12)!)
            data.barWidth = 0.45
            data.setValueFormatter(StackedBarValueFormatter(isHorizontal: false))

            chartView.data = data
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
            chartView.xAxis.labelCount = days.count
            chartView.legend.enabled = false

            let chartViewWidth: CGFloat = fixedBarWidth / 0.45 * CGFloat(days.count)

            chartView.flex.width(chartViewWidth)
            chartView.flex.height(220)
            flex.height(250)

        } else {
            chartView.clear()
            chartView.flex.height(0)
            flex.height(0)
        }

        containerLayoutDelegate?.layout()
    }

    fileprivate func updateFilterText(timeUnit: TimeUnit) {
        let filterText: String!

        switch timeUnit {
        case .week: filterText = R.string.localizable.byDay()
        case .year: filterText = R.string.localizable.byMonth()
        case .decade: filterText = R.string.localizable.byYear()
        }

        headingLabel.text = filterText
    }
}

extension FilterDayView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        chartView.highlightValues(nil)

        guard let selectedDate = entry.data else { return }

        switch section {
        case .post:
            navigatorDelegate?.goToPostListScreen(filterBy: .day, filterValue: selectedDate)
        case .reaction:
            navigatorDelegate?.goToReactionListScreen(filterBy: .day, filterValue: selectedDate)
        default:
            return
        }
    }
}
