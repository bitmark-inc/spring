//
//  AdsCategoryView.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/9/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class AdsCategoryView: UIView {

    // MARK: - Properties
    lazy var headerLabel = makeHeaderLabel()
    lazy var descriptionLabel = makeDescriptionLabel()
    lazy var adsCategoryInfoView = makeAdsCategoryInfoView()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.define({ (flex) in
            flex.addItem(SectionSeparator())

            flex.addItem()
                .padding(34, 18, 34, 16)
                .define { (flex) in
                    flex.addItem(headerLabel)
                    flex.addItem(descriptionLabel).marginTop(7)
                    flex.addItem(adsCategoryInfoView).marginTop(10).marginLeft(18).width(100%)
                }
        })
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: InsightViewController) {
        weak var container = container

        container?.thisViewModel.realmAdsCategoriesRelay.filterNil()
            .subscribe(onNext: { [weak self] (adsCategoryInfos) in
                guard let self = self,
                    let adsCategories = adsCategoryInfos.dictionaryWithValues(forKeys: ["value"])["value"] as? [String]
                    else {
                        return
                }

                self.fillData(adsCategories: adsCategories)
            }).disposed(by: disposeBag)
    }

    fileprivate func fillData(adsCategories: [String]) {
        adsCategoryInfoView.removeSubviews()
        if adsCategories.count > 0 {
            for adsCategory in adsCategories {
                adsCategoryInfoView.flex.define { (flex) in
                    flex.addItem(makeAdsCategoryRow(adsCategory: adsCategory)).width(100%).marginTop(16)
                }
            }
        } else {
            adsCategoryInfoView.flex.define { (flex) in
                flex.addItem(makeNoDataView())
            }
        }

        adsCategoryInfoView.flex.layout()
        containerLayoutDelegate?.layout()
    }
}

extension AdsCategoryView {
    fileprivate func makeHeaderLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.adsCategoryHeader(),
            font: R.font.domaineSansTextLight(size: 22),
            colorTheme: .black, lineHeight: 1.056)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.adsCategoryDescription(),
            font: R.font.atlasGroteskLight(size: 12),
            colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeAdsCategoryInfoView() -> UIView {
        return UIView()
    }

    fileprivate func makeAdsCategoryRow(adsCategory: String) -> UIView {
        let view = UIView()

        let markView = UIView()
        markView.backgroundColor = ColorTheme.cognac.color

        let adsCategoryLabel = Label()
        adsCategoryLabel.numberOfLines = 0
        adsCategoryLabel.apply(
            text: adsCategory, font: R.font.atlasGroteskLight(size: 14),
            colorTheme: .black, lineHeight: 1.236)

        view.flex
            .direction(.row)
            .define { (flex) in
                flex.addItem(markView).width(2).height(100%)
                flex.addItem(adsCategoryLabel).marginLeft(7).width(100%)
            }

        return view
    }

    fileprivate func makeNoDataView() -> Label {
        let label = Label()
        label.apply(text: R.string.localizable.noDataAvailable(),
                    font: R.font.atlasGroteskLight(size: Size.ds(14)),
                    colorTheme: .black,
                    lineHeight: 1.056)
        return label
    }
}
