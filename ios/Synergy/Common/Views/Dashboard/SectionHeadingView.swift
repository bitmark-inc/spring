//
//  SectionHeadingView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class SectionHeadingView: UIView {

    // MARK: - Properties
    private let countLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 24))
    private let actionDescriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 10))

    var section: Section = .posts
    var dataObserver: Disposable? // stop observing old-data
    let disposeBag = DisposeBag()

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column).define { (flex) in
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem()
                .backgroundColor(UIColor(hexString: "#828180")!)
                .marginTop(3)
                .marginLeft(0)
                .marginRight(0)
                .height(1)
            flex.addItem().direction(.row).define { (flex) in
                flex.alignItems(.start)
                flex.padding(38, 18, 28, 18)
                flex.addItem(countLabel)
                flex.addItem(actionDescriptionLabel).marginLeft(7)
            }
        }
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
                        self.dataObserver = container.postUsageObservable
                            .map { $0.quantity }
                            .subscribe(onNext: { [weak self] in
                                self?.fillData(
                                    countText: R.string.localizable.numberOfPosts("\($0)"),
                                    actionDescriptionText: R.string.localizable.you_made())
                            })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(
                            countText: R.string.localizable.numberOfPosts("0"),
                            actionDescriptionText: R.string.localizable.you_made())
                    }
                })
                .disposed(by: disposeBag)

        case .reactions:
            container.thisViewModel.realmReactionUsageRelay
                .subscribe(onNext: { [weak self] (usage) in
                    guard let self = self else { return }
                    if usage != nil {
                        self.dataObserver?.dispose()
                        self.dataObserver = container.reactionUsageObservable
                            .map { $0.quantity }
                            .subscribe(onNext: { [weak self] in
                                self?.fillData(
                                    countText: R.string.localizable.numberOfReactions("\($0)"),
                                    actionDescriptionText: R.string.localizable.you_gave())
                            })
                    } else {
                        self.dataObserver?.dispose()
                        self.fillData(
                            countText: R.string.localizable.numberOfReactions("0"),
                            actionDescriptionText: R.string.localizable.you_gave())
                    }
                })
                .disposed(by: disposeBag)

        default:
            break
        }
    }

    func fillData(countText: String?, actionDescriptionText: String?) {
        countLabel.text = countText
        actionDescriptionLabel.text = actionDescriptionText
        countLabel.flex.markDirty()
        actionDescriptionLabel.flex.markDirty()
        flex.layout()
    }
}
