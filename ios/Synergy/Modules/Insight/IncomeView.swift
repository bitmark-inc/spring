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
    var dataObserver: Disposable? // stop observing old-data
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .define { (flex) in
                flex.addItem(SectionSeparator())

                flex.addItem()
                    .padding(30, 0, 30, 0)
                    .alignItems(.center).define { (flex) in
                        flex.addItem(amountLabel)
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
                                self?.fillData(amount: amount)
                            })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(amount: nil)
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    func fillData(amount: Double?) {
        if let amount = amount {
            amountLabel.text = String(format: "$%.02f", amount)
        } else {
            amountLabel.text = "--"
        }

        amountLabel.flex.markDirty()
        flex.layout()
    }
}

extension IncomeView {
    fileprivate func makeAmountLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.avenir(size: 45),
            colorTheme: ColorTheme.cognac)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.localizable.incomeDescription(),
            font: R.font.atlasGroteskThin(size: Size.ds(12)),
            colorTheme: ColorTheme.black)
        return label
    }
}
