//
//  InsightViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import BitmarkSDK
import RxSwift
import RxCocoa
import RxRealm
import FlexLayout
import RealmSwift
import Realm
import SwiftDate

class InsightViewController: ViewController {
    lazy var thisViewModel = viewModel as! InsightViewModel

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var insightView = UIView()
    lazy var headingView = makeHeadingView()
    lazy var timelineView = makeTimelineView()
    lazy var badgeView = makeBadgeView()
    lazy var fbIncomeView = makeFBIncomeView()
    lazy var moodHeadingView = makeSectionHeadingView(section: .mood)
    lazy var moodView = makeMoodView()

    // SECTION: FB Income
    lazy var incomeInsightObservable: Observable<Insight> = {
        thisViewModel.realmIncomeInsightRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    // SECTION: Reaction
    lazy var moodInsightObservable: Observable<Insight> = {
        thisViewModel.realmMoodInsightRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    var segmentDistances: [TimeUnit: Int] = [
        .week: 0, .year: 0, .decade: 0
    ]

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? InsightViewModel else { return }
        viewModel.fetchInsight()

        thisViewModel.dateRelay
            .subscribe(onNext: { [weak self] (startDate) in
                guard let self = self else { return }

                let timeUnit = self.thisViewModel.timeUnitRelay.value
                let datePeriod = startDate.extractDatePeriod(timeUnit: timeUnit)

                let distance = self.segmentDistances[timeUnit]!
                self.timelineView.bindData(
                    periodName: timeUnit.meaningTimeText(with: distance),
                    periodDescription: datePeriod.makeTimelinePeriodText(in: timeUnit),
                    distance: distance)
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = insightView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        themeForContentView()

        insightView.flex.define { (flex) in
            flex.addItem(headingView)
            flex.addItem(timelineView)
            flex.addItem(badgeView)
            flex.addItem(fbIncomeView)
            flex.addItem(moodHeadingView)
            flex.addItem(moodView)
        }

        scroll.addSubview(insightView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }
    }
}

// MARK: - ContainerLayoutDelegate
extension InsightViewController: ContainerLayoutDelegate {
    func layout() {
        insightView.flex.markDirty()
        insightView.flex.layout(mode: .adjustHeight)
        scroll.contentSize = insightView.frame.size
    }
}

extension InsightViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(
            title: R.string.localizable.insights().localizedUppercase,
            color:  ColorTheme.internationalKleinBlue.color)
        headingView.subTitle = R.string.localizable.howfacebookusesyoU()
        headingView.accountButton.rx.tap.bind { [weak self] in
            self?.gotoAccountScreen()
        }.disposed(by: disposeBag)
        return headingView
    }

    fileprivate func makeTimelineView() -> TimeFilterView {
        let timeFilterView = TimeFilterView()
        timeFilterView.timelineDelegate = self
        return timeFilterView
    }

    fileprivate func makeBadgeView() -> InsightBadgeView {
        let badgeView = InsightBadgeView()
        badgeView.setProperties(container: self)
        return badgeView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section)
        return sectionHeadingView
    }

    fileprivate func makeFBIncomeView() -> IncomeView {
        let incomeView = IncomeView()
        incomeView.containerLayoutDelegate = self
        incomeView.setProperties(section: .fbIncome, container: self)
        return incomeView
    }

    fileprivate func makeMoodView() -> MoodView {
        let moodView = MoodView()
        moodView.containerLayoutDelegate = self
        moodView.setProperties(section: .mood, container: self)
        return moodView
    }
}

// MARK: - TimelineDelegate
extension InsightViewController: TimelineDelegate {
    func updateTimeUnit(_ timeUnit: TimeUnit) {
        let distance = segmentDistances[timeUnit]!
        let updatedDate: Date!

        switch timeUnit {
        case .week:
            let currentDateRegion = Date().adding(.weekOfMonth, value: distance).in(.english)
            updatedDate = currentDateRegion.dateAtStartOf(.weekOfMonth).date

        case .year:
            let distance = segmentDistances[timeUnit]!
            let currentDateRegion = Date().adding(.year, value: distance).in(.english)
            updatedDate = currentDateRegion.dateAtStartOf(.year).date

        case .decade:
            let distance = segmentDistances[timeUnit]!
            updatedDate = Date()?.in(.english).dateAtStartOfDecade(distance: distance).date
        }

        thisViewModel.timeUnitRelay.accept(timeUnit)
        thisViewModel.dateRelay.accept(updatedDate)
    }

    func nextPeriod() {
        let currentDate = thisViewModel.dateRelay.value
        let nextDate: Date!

        switch thisViewModel.timeUnitRelay.value {
        case .week: nextDate = currentDate + 1.weeks
        case .year: nextDate = currentDate + 1.years
        case .decade: nextDate = currentDate + 10.years
        }

        let timeUnit = thisViewModel.timeUnitRelay.value
        segmentDistances[timeUnit]! += 1
        thisViewModel.dateRelay.accept(nextDate)
    }

    func prevPeriod() {
        let currentDate = thisViewModel.dateRelay.value
        let prevDate: Date!

        switch thisViewModel.timeUnitRelay.value {
        case .week: prevDate = currentDate - 1.weeks
        case .year: prevDate = currentDate - 1.years
        case .decade: prevDate = currentDate - 10.years
        }

        let timeUnit = thisViewModel.timeUnitRelay.value
        segmentDistances[timeUnit]! -= 1
        thisViewModel.dateRelay.accept(prevDate)
    }
}

// MARK: - Navigator
extension InsightViewController {
    fileprivate func goToPostListScreen(filterScope: FilterScope) {
        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    fileprivate func gotoAccountScreen() {
        let viewModel = AccountViewModel()
        navigator.show(segue: .account(viewModel: viewModel), sender: self)
    }
}
