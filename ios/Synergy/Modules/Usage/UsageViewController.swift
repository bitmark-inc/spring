//
//  UsageViewController.swift
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

protocol ContainerLayoutDelegate: class {
    func layout()
}

protocol TimelineDelegate: class {
    func updateTimeUnit(_ timeUnit: TimeUnit)
    func nextPeriod()
    func prevPeriod()
}

protocol NavigatorDelegate: class {
    func goToPostListScreen(filterBy: GroupKey, filterValue: Any)
    func goToReactionListScreen(filterBy: GroupKey, filterValue: Any)
}

class UsageViewController: ViewController {

    lazy var thisViewModel = viewModel as! UsageViewModel

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var usageView = UIView()
    lazy var headingView = makeHeadingView()
    lazy var timelineView = makeTimelineView()
    lazy var badgeView = makeBadgeView()
    lazy var postsHeadingView = makeSectionHeadingView(section: .post)
    lazy var postsFilterTypeView = makeFilterTypeView(section: .post)
    lazy var postsFilterDayView = makeFilterDayView(section: .post)
    lazy var postsFilterFriendView = makeFilterGeneralView(section: .post, groupBy: 
        .friend)
    lazy var postsFilterPlaceView = makeFilterGeneralView(section: .post, groupBy:
        .place)
    lazy var reationsHeadingView = makeSectionHeadingView(section: .reaction)
    lazy var reactionsFilterTypeView = makeFilterTypeView(section: .reaction)
    lazy var reactionsFilterDayView = makeFilterDayView(section: .reaction)
    lazy var reactionsFilterFriendView = makeFilterGeneralView(section: .reaction, groupBy:
        .friend)

    // SECTION: Post
    lazy var postUsageObservable: Observable<Usage> = {
        thisViewModel.realmPostUsageRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    lazy var groupsPostUsageObservable: Observable<Groups> = {
        postUsageObservable
            .map { $0.groups }
            .map { try GroupsConverter(from: $0).value }
    }()

    // SECTION: Reaction
    lazy var reactionUsageObservable: Observable<Usage> = {
        thisViewModel.realmReactionUsageRelay.filterNil()
            .flatMap { Observable.from(object: $0) }
    }()

    lazy var groupsReactionUsageObservable: Observable<Groups> = {
        reactionUsageObservable
            .map { $0.groups }
            .map { try GroupsConverter(from: $0).value }
    }()

    var segmentDistances: [TimeUnit: Int] = [
        .week: 0, .year: 0, .decade: 0
    ]

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        
        guard let viewModel = viewModel as? UsageViewModel else { return }

        viewModel.fetchDataResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenFetchingData(error: error)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        viewModel.fetchUsage()

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

    func errorWhenFetchingData(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.signInError())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = usageView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        themeForContentView()

        usageView.flex.define { (flex) in
            flex.addItem(headingView)
            flex.addItem(timelineView)
            flex.addItem(badgeView)
            flex.addItem(postsHeadingView)
            flex.addItem(postsFilterTypeView)
            flex.addItem(postsFilterDayView)
            flex.addItem(postsFilterFriendView)
            flex.addItem(postsFilterPlaceView)
            flex.addItem(reationsHeadingView)
            flex.addItem(reactionsFilterTypeView)
            flex.addItem(reactionsFilterDayView)
            flex.addItem(reactionsFilterFriendView)
        }

        scroll.addSubview(usageView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }
    }
}

extension UsageViewController {
    fileprivate func makeHeadingView() -> HeadingView {
        let headingView = HeadingView()
        headingView.setHeading(title: R.string.localizable.usage().localizedUppercase, color:  UIColor(hexString: "#932C19"))
        headingView.subTitle = R.string.localizable.howyouusefacebooK()
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

    fileprivate func makeBadgeView() -> UsageBadgeView {
        let badgeView = UsageBadgeView()
        badgeView.setProperties(container: self)
        return badgeView
    }

    fileprivate func makeSectionHeadingView(section: Section) -> SectionHeadingView {
        let sectionHeadingView = SectionHeadingView()
        sectionHeadingView.setProperties(section: section, container: self)
        return sectionHeadingView
    }

    fileprivate func makeFilterTypeView(section: Section) -> FilterTypeView {
        let filterTypeView = FilterTypeView()
        filterTypeView.setProperties(section: section, container: self)
        filterTypeView.containerLayoutDelegate = self
        filterTypeView.navigatorDelegate = self
        filterTypeView.selectionEnabled = true
        return filterTypeView
    }

    fileprivate func makeFilterDayView(section: Section) -> FilterDayView {
        let filterDayView = FilterDayView()
        filterDayView.setProperties(section: section, container: self)
        filterDayView.containerLayoutDelegate = self
        filterDayView.navigatorDelegate = self
        return filterDayView
    }

    fileprivate func makeFilterGeneralView(section: Section, groupBy groupKey: GroupKey) -> FilterGeneralView {
        let filterGeneralView = FilterGeneralView()
        filterGeneralView.setProperties(section: section, groupKey: groupKey, container: self)
        filterGeneralView.containerLayoutDelegate = self
        filterGeneralView.navigatorDelegate = self
        return filterGeneralView
    }
}

// MARK: - ContainerLayoutDelegate
extension UsageViewController: ContainerLayoutDelegate {
    func layout() {
        usageView.flex.markDirty()
        usageView.flex.layout(mode: .adjustHeight)
        scroll.contentSize = usageView.frame.size
    }
}

// MARK: - TimelineDelegate
extension UsageViewController: TimelineDelegate {
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

// MARK: - NavigatorDelegate
extension UsageViewController: NavigatorDelegate {
    func goToPostListScreen(filterBy: GroupKey, filterValue: Any) {
        let filterScope = FilterScope(
            date: thisViewModel.dateRelay.value,
            timeUnit: thisViewModel.timeUnitRelay.value,
            section: .post,
            filterBy: filterBy, filterValue: filterValue)

        let viewModel = PostListViewModel(filterScope: filterScope)
        navigator.show(segue: .postList(viewModel: viewModel), sender: self)
    }

    func goToReactionListScreen(filterBy: GroupKey, filterValue: Any) {
        let filterScope = FilterScope(
            date: thisViewModel.dateRelay.value,
            timeUnit: thisViewModel.timeUnitRelay.value,
            section: .reaction,
            filterBy: filterBy, filterValue: filterValue)

        let viewModel = ReactionListViewModel(filterScope: filterScope)
        navigator.show(segue: .reactionList(viewModel: viewModel), sender: self)
    }
}

// MARK: - Navigator
extension UsageViewController {
    fileprivate func gotoAccountScreen() {
        let viewModel = AccountViewModel()
        navigator.show(segue: .account(viewModel: viewModel), sender: self)
    }
}

