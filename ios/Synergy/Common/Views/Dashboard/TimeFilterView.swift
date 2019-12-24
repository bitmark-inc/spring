//
//  TimeFilterView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class TimeFilterView: UIView {
    private let filterSegment = FilterSegment(elements: [R.string.localizable.week().localizedUppercase,
                                                         R.string.localizable.year().localizedUppercase,
                                                         R.string.localizable.decade().localizedUppercase
    ])

    weak var timelineDelegate: TimelineDelegate?

    private lazy var previousPeriodButton = makePrevPeriodButton()
    private lazy var nextPeriodButton = makeNextPeriodButton()
    private lazy var periodNameLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 18))
    private lazy var periodDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))

    let filterChangeSubject = PublishSubject<TimeUnit>()
    let disposeBag = DisposeBag()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        periodNameLabel.textAlignment = .center
        periodDescriptionLabel.textAlignment = .center

        flex.direction(.column).define { (flex) in
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

    private func bindData() {
        filterSegment.rx.selectedIndex
            .map { (index) -> TimeUnit in
                switch index {
                case 0:     return .week
                case 1:     return .year
                case 2:     return .decade
                default:    return .week
                }
            }
            .bind(to: filterChangeSubject)
            .disposed(by: disposeBag)

        filterChangeSubject.subscribe(onNext: { [weak self] (timeUnit) in
            self?.timelineDelegate?.updateTimeUnit(timeUnit)
        }).disposed(by: disposeBag)

        previousPeriodButton.rx.tap.bind { [weak self] in
            self?.timelineDelegate?.prevPeriod()
        }.disposed(by: disposeBag)

        nextPeriodButton.rx.tap.bind { [weak self] in
            self?.timelineDelegate?.nextPeriod()
        }.disposed(by: disposeBag)
    }

    func bindData(periodName: String, periodDescription: String, distance: Int) {
        periodNameLabel.text = periodName.localizedUppercase
        periodDescriptionLabel.text = periodDescription
        nextPeriodButton.isEnabled = distance < 0
    }
}

extension TimeFilterView {
    fileprivate func makePrevPeriodButton() -> Button {
        let button = Button()
        button.setImage(R.image.previous_period(), for: .normal)
        button.setImage(R.image.disabled_previous_period(), for: .disabled)
        return button
    }

    fileprivate func makeNextPeriodButton() -> Button {
        let button = Button()
        button.setImage(R.image.next_period()!, for: .normal)
        button.setImage(R.image.disabled_next_period(), for: .disabled)
        button.isEnabled = false
        return button
    }
}
