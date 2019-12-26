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
    fileprivate let sectionHeight: CGFloat = 170

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    var dataObserver: Disposable? // stop observing old-data
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .define { (flex) in
                flex.addItem(SectionSeparator())

                flex.addItem()
                    .height(sectionHeight)
                    .alignItems(.center).define { (flex) in
                        flex.addItem(amountLabel).marginTop(30)
                        flex.addItem(descriptionLabel).marginTop(20)
                    }
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section, container: InsightViewController) {
        switch section {
        case .fbIncome:
            container.thisViewModel.realmIncomeInsightRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.incomeInsightObservable
                            .map { $0.value }
                            .subscribe(onNext: { [weak self] (amount) in
                                let timeUnit = container.thisViewModel.timeUnitRelay.value
                                let distance = container.segmentDistances[timeUnit]!

                                self?.fillData(
                                    amount: amount,
                                    descriptionText: R.string.localizable.incomeDescription(timeUnit.meaningTimeText(with: distance).lowercased()))
                            })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(amount: nil, descriptionText: nil)
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    func fillData(amount: Double?, descriptionText: String?) {
        if let amount = amount {
            amountLabel.text = String(format: "$%.02f", amount)
            descriptionLabel.text = descriptionText
            amountLabel.flex.markDirty()
            descriptionLabel.flex.markDirty()
            flex.height(sectionHeight)
        } else {
            flex.height(0)
        }

        flex.markDirty()
        containerLayoutDelegate?.layout()
    }
}

extension IncomeView {
    fileprivate func makeAmountLabel() -> Label {
        let label = Label()
        label.apply(
            text: "",
            font: R.font.avenir(size: 45),
            colorTheme: ColorTheme.cognac)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.apply(
            text: "",
            font: R.font.atlasGroteskThin(size: Size.ds(12)),
            colorTheme: ColorTheme.black)
        return label
    }
}
