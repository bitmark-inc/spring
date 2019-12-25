//
//  UsageBadgeView.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class UsageBadgeView: UIView {

    let disposeBag = DisposeBag()

    private lazy var postDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralPost().localizedUppercase
        return u
    }()

    private lazy var reactionsDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralReaction().localizedUppercase
        return u
    }()

    private lazy var messagesDataBadgeView: DataBadgeView = {
        let u = DataBadgeView()
        u.descriptionLabel.text = R.string.localizable.pluralMessage().localizedUppercase
        return u
    }()

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
                flex.addItem(postDataBadgeView)
                flex.addItem(reactionsDataBadgeView)
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: UsageViewController) {
        var postUsageObserver: Disposable?
        var reactionUsageObserver: Disposable?

        container.thisViewModel.realmPostUsageRelay
            .subscribe(onNext: { [weak self] (usage) in
                guard let self = self else { return }
                if usage != nil {
                    postUsageObserver?.dispose()
                    postUsageObserver = container.postUsageObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { (postBadge) in
                            self.fillData(with: (badge: postBadge, section: .posts))
                        })
                } else {
                    postUsageObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .posts))
                }
            })
            .disposed(by: disposeBag)

        container.thisViewModel.realmReactionUsageRelay
            .subscribe(onNext: { [weak self] (usage) in
                guard let self = self else { return }
                if usage != nil {
                    reactionUsageObserver?.dispose()
                    reactionUsageObserver = container.reactionUsageObservable
                        .map { $0.diffFromPrevious }
                        .subscribe(onNext: { (reactionBadge) in
                            self.fillData(with: (badge: reactionBadge, section: .reactions))
                        })
                } else {
                    postUsageObserver?.dispose()
                    self.fillData(with: (badge: nil, section: .reactions))
                }
            })
            .disposed(by: disposeBag)
    }

    func fillData(with data: (badge: Double?, section: Section)) {
        let badge = data.badge
        switch data.section {
        case .posts:
            postDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            postDataBadgeView.percentageLabel.text = precentageText(with: badge)
            updateLayout(for: postDataBadgeView, with: badge)

        case .reactions:
            reactionsDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            reactionsDataBadgeView.percentageLabel.text = precentageText(with: badge)
            updateLayout(for: reactionsDataBadgeView, with: badge)

        case .messages:
            messagesDataBadgeView.updownImageView.image = getUpDownImageView(with: badge)
            messagesDataBadgeView.percentageLabel.text = precentageText(with: badge)
            updateLayout(for: messagesDataBadgeView, with: badge)

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


final class DataBadgeView: UIView {
    private let disposeBag = DisposeBag()

    let updownImageView = UIImageView()
    let percentageLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 15))
    let descriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))

    override init(frame: CGRect) {
        super.init(frame: frame)

        let toplineView = UIView()
        toplineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.center)
            flex.addItem(updownImageView).height(16)
            flex.addItem(percentageLabel).grow(1)
        }

        self.flex.direction(.column).define { (flex) in
            flex.alignItems(.stretch)
            flex.addItem(toplineView)
            flex.addItem(descriptionLabel).marginTop(6)
        }

        percentageLabel.text = "--"
        percentageLabel.textAlignment = .center

        themeService.rx
            .bind({ $0.blackTextColor }, to: updownImageView.rx.tintColor)
            .bind({ $0.blackTextColor }, to: percentageLabel.rx.textColor)
            .bind({ $0.blackTextColor }, to: descriptionLabel.rx.textColor)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
