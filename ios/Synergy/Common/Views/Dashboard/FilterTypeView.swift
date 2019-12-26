//
//  FilterTypeView.swift
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

class FilterTypeView: UIView {

    // MARK: - Properties
    private let headingLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    private let chartView = HorizontalBarChartView()
    private let fixedBarHeight: CGFloat = 4
    private lazy var noActivityView = makeNoActivityView()

    var section: Section = .posts
    weak var navigatorDelegate: NavigatorDelegate?
    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    var dataObserver: Disposable? // stop observing old-data
    let disposeBag = DisposeBag()

    var selectionEnabled = true {
        didSet {
            chartView.highlightPerTapEnabled = selectionEnabled
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        headingLabel.text = R.string.localizable.byType()

        flex.direction(.column).define { (flex) in
            flex.addItem(headingLabel).marginLeft(18).marginRight(18)
            flex.addItem(chartView).margin(0, 20, 15, 0).height(200)
            flex.addItem(noActivityView).position(.absolute).top(0).left(18)
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
        chartView.xAxisRenderer = CustomxAxisRender(
            viewPortHandler: xAxisRender.viewPortHandler,
            xAxis: xAxis,
            transformer: xAxisRender.transformer,
            chart: chartView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: UsageViewController) {
        self.section = section

        switch section {
        case .posts:
            container.thisViewModel.realmPostUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.groupsPostUsageObservable
                            .map { $0.type }
                            .map { GraphDataConverter.getDataGroupByType(with: $0, in: .posts) }
                            .subscribe(onNext: { [weak self] (data) in
                                self?.fillData(with: data)
                            })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(with: nil)
                    }
                })
                .disposed(by: disposeBag)

        case .reactions:
            container.thisViewModel.realmReactionUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.groupsReactionUsageObservable
                            .map { $0.type }
                            .map { GraphDataConverter.getDataGroupByType(with: $0, in: .reactions) }
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

    fileprivate func fillData(with data: [(String, Double)]?) {
        if let data = data {
            var values = [String]()
            var entries = [BarChartDataEntry]()

            for (index, (typeKey, quantity)) in data.reversed().enumerated() {
                values.append("graph.key.\(typeKey)".localized())
                entries.append(BarChartDataEntry(x: Double(index), y: quantity, data: typeKey))
            }

            let barChartDataSet = BarChartDataSet(entries: entries)

            switch section {
            case .posts:
                barChartDataSet.colors = PostType.barChartColors.reversed()
            case .reactions:
                barChartDataSet.colors = ReactionType.barChartColors.reversed()
            default:
                break
            }

            let barData = BarChartData(dataSets: [barChartDataSet])
            barData.setValueFont(R.font.atlasGroteskLight(size: 12)!)
            barData.barWidth = 0.15
            barData.setValueFormatter(DefaultValueFormatter(decimals: 0))

            chartView.data = barData
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: values)
            chartView.xAxis.labelCount = data.count

            noActivityView.isHidden = true
            headingLabel.isHidden = false
            let chartViewHeight: CGFloat = (fixedBarHeight / 0.15 + 12) * CGFloat(data.count)
            chartView.flex.height(chartViewHeight)
            
        } else {
            noActivityView.isHidden = false
            headingLabel.isHidden = true
            chartView.clear()
            chartView.flex.height(0)
        }

        containerLayoutDelegate?.layout()
    }
}

extension FilterTypeView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        chartView.highlightValues(nil)

        guard let typeKey = entry.data as? String else { return }
        switch section {
        case .posts:
            guard let type = PostType(rawValue: typeKey) else { return }
            navigatorDelegate?.goToPostListScreen(filterBy: .type, filterValue: type)
        case .reactions:
            guard let type = ReactionType(rawValue: typeKey) else { return }
            navigatorDelegate?.goToReactionListScreen(filterBy: .type, filterValue: type)
        default:
            return
        }
    }
}

extension FilterTypeView {
    fileprivate func makeNoActivityView() -> Label {
        let label = Label()
        label.apply(text: R.string.localizable.graphNoActivity(),
                    font: R.font.atlasGroteskLight(size: Size.ds(14)),
                    colorTheme: .black,
                    lineHeight: 1.056)
        label.isHidden = true
        return label
    }
}
