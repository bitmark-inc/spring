//
//  DataBadgeView.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/2/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

final class DataBadgeView: UIView {
    fileprivate let disposeBag = DisposeBag()

    lazy var updownImageView = UIImageView()
    lazy var percentageLabel = makePercentageLabel()
    lazy var descriptionLabel = makeDescriptionLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let toplineView = UIView()
        toplineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.center)
            flex.addItem(updownImageView).height(16)
            flex.addItem(percentageLabel).grow(1)
        }

        flex.width(100)
            .direction(.row).define { (flex) in
                flex.addItem().define { (flex) in
                    flex.addItem(toplineView)
                    flex.addItem(descriptionLabel).marginTop(6)
                }
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

    func updateValue(with badge: Double?) {
        if badge != nil {
            percentageLabel.textAlignment = .left
            updownImageView.flex.width(16)
        } else {
            percentageLabel.textAlignment = .center
            updownImageView.flex.width(0)
        }

        percentageLabel.flex.markDirty()
        updownImageView.flex.markDirty()
        flex.layout()
    }

    fileprivate func makePercentageLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.atlasGroteskLight(size: 15), colorTheme: .black)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.atlasGroteskLight(size: 14), colorTheme: .black)
        return label
    }
}
