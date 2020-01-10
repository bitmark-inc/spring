//
//  IncomeView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class IncomeView: UIView {

    // MARK: - Properties
    fileprivate lazy var amountLabel = makeAmountLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .define { (flex) in
                flex.addItem(SectionSeparator())

                flex.addItem()
                    .padding(30, 0, 40, 0)
                    .alignItems(.center).define { (flex) in
                        flex.addItem(amountLabel)
                        flex.addItem(descriptionLabel).marginTop(18)
                    }
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: InsightViewController) {
        weak var container = container

        switch section {
        case .fbIncome:
            container?.realmInsightObservable
                .subscribe(onNext: { [weak self] (insight) in
                    self?.fillData(amount: insight.fbIncome, since: insight.fbIncomeFrom)
                }).disposed(by: disposeBag)

        default:
            break
        }
    }

    func fillData(amount: Double?, since: Date) {
        if let amount = amount, amount >= 0 {
            amountLabel.text = String(format: "$%.02f", amount)
            descriptionLabel.setText(R.string.phrase.incomeDescription(
                since.toFormat(Constant.TimeFormat.date)))
        } else {
            amountLabel.text = "--"
            descriptionLabel.setText(R.string.localizable.noDataAvailable())
        }

        amountLabel.flex.markDirty()
        descriptionLabel.flex.markDirty()
        flex.layout()
    }
}

extension IncomeView {
    fileprivate func makeAmountLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.atlasGroteskRegular(size: 42),
            colorTheme: ColorTheme.cognac)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.atlasGroteskLight(size: Size.ds(12)),
            colorTheme: ColorTheme.black)
        return label
    }
}
