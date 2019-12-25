//
//  InsightBadgeView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class InsightBadgeView: UIView {

    let disposeBag = DisposeBag()

    private lazy var fbIncomeDataBadgeView = makeBadgeView(section: .fbIncome)
    private lazy var moodDataBadgeView = makeBadgeView(section: .mood)

    let emptyPercentage = "--"

    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.row)
            .paddingLeft(18).paddingRight(18).marginBottom(30)
            .justifyContent(.spaceAround)
            .define { (flex) in
                flex.addItem(fbIncomeDataBadgeView)
                flex.addItem(moodDataBadgeView)
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: InsightViewController) {
        var fbIncomeInsightObserver: Disposable?
        var moodInsightObserver: Disposable?

        container.thisViewModel.realmIncomeInsightRelay
            .subscribe(onNext: { [weak self] (insight) in
                guard let self = self else { return }
                if insight != nil {
                    fbIncomeInsightObserver?.dispose()
                    fbIncomeInsightObserver = container.incomeInsightObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { (fbIncomeBadge) in
                            self.fillData(with: (badge: fbIncomeBadge, section: .fbIncome))
                        })
                } else {
                    fbIncomeInsightObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .fbIncome))
                }
            })
            .disposed(by: disposeBag)

        container.thisViewModel.realmMoodInsightRelay
            .subscribe(onNext: { [weak self] (usage) in
                guard let self = self else { return }
                if usage != nil {
                    moodInsightObserver?.dispose()
                    moodInsightObserver = container.moodInsightObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { (moodBadge) in
                            self.fillData(with: (badge: moodBadge, section: .mood))
                        })
                } else {
                    moodInsightObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .reactions))
                }
            })
            .disposed(by: disposeBag)
    }

    func fillData(with data: (badge: Double?, section: Section)) {
        let badge = data.badge
        switch data.section {
        case .fbIncome:
            fbIncomeDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            fbIncomeDataBadgeView.percentageLabel.text = precentageText(with: badge)
            updateLayout(for: fbIncomeDataBadgeView, with: badge)

        case .mood:
            moodDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            moodDataBadgeView.percentageLabel.text = precentageText(with: badge)
            updateLayout(for: moodDataBadgeView, with: badge)

        default:
            break
        }
    }

    fileprivate func getUpDownImageView(with badge: Double?) -> UIImage? {
        guard let badge = badge else { return nil }
        if badge > 0 {
            return R.image.usage_up()!
        } else if badge == 0 {
            return R.image.usageEqual()
        } else {
            return R.image.usage_down()!
        }
    }

    fileprivate func precentageText(with badge: Double?) -> String {
        guard let badge = badge else { return emptyPercentage }
        let number = NSNumber(value: abs(Int(badge * 100)))
        guard let formattedNumber = numberFormatter.string(from: number) else { return "" }
        return "  \(formattedNumber)%"
    }

    fileprivate func updateLayout(for badgeView: DataBadgeView, with badge: Double?) {
        if badge != nil {
            badgeView.percentageLabel.textAlignment = .left
            badgeView.updownImageView.flex.width(16)
        } else {
            badgeView.percentageLabel.textAlignment = .center
            badgeView.updownImageView.flex.width(0)
        }

        badgeView.percentageLabel.flex.markDirty()
        badgeView.updownImageView.flex.markDirty()
    }
}

extension InsightBadgeView {
    fileprivate func makeBadgeView(section: Section) -> DataBadgeView {
        let dataBadgeView = DataBadgeView()
        let descriptionText: String!

        switch section {
        case .fbIncome:
            descriptionText = R.string.localizable.income().localizedUppercase
        case .mood:
            descriptionText = R.string.localizable.mood().localizedUppercase
        default:
            descriptionText = ""
        }

        dataBadgeView.descriptionLabel.text = descriptionText
        return dataBadgeView
    }
}
