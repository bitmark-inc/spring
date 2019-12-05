//
//  InsightBadgeCollectionViewCell.swift
//  Synergy
//
//  Created by Anh Nguyen on 12/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout

class InsightBadgeCollectionViewCell: CollectionViewCell {
    
    private lazy var postDataBadgeView: InsightDataBadgeView = {
        let u = InsightDataBadgeView()
        u.updownImageView.image = R.image.usage_up()
        u.percentageLabel.text = "5%"
        u.descriptionLabel.text = "POSTS".localized()
        return u
    }()
    
    private lazy var reactionsDataBadgeView: InsightDataBadgeView = {
        let u = InsightDataBadgeView()
        u.updownImageView.image = R.image.usage_down()
        u.percentageLabel.text = "18%"
        u.descriptionLabel.text = "REACTIONS".localized()
        return u
    }()
    
    private lazy var messagesDataBadgeView: InsightDataBadgeView = {
        let u = InsightDataBadgeView()
        u.updownImageView.image = R.image.usage_up()
        u.percentageLabel.text = "22%"
        u.descriptionLabel.text = "MESSAGES".localized()
        return u
    }()
    
    var timeUnit: TimeUnit = .week {
        didSet {
            switch timeUnit {
            case .week:
                postDataBadgeView.percentageLabel.text = "25%"
                reactionsDataBadgeView.percentageLabel.text = "29%"
                messagesDataBadgeView.percentageLabel.text = "69%"
            case .year:
                postDataBadgeView.percentageLabel.text = "15%"
                reactionsDataBadgeView.percentageLabel.text = "21%"
                messagesDataBadgeView.percentageLabel.text = "17%"
            case .decade:
                postDataBadgeView.percentageLabel.text = "70%"
                reactionsDataBadgeView.percentageLabel.text = "68%"
                messagesDataBadgeView.percentageLabel.text = "69%"
            }
            postDataBadgeView.flex.markDirty()
            reactionsDataBadgeView.flex.markDirty()
            messagesDataBadgeView.flex.markDirty()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.flex.direction(.column).define { (flex) in
            flex.alignItems(.stretch)
            flex.addItem().define { (flex) in
                flex.direction(.row)
                flex.alignItems(.stretch)
                flex.paddingLeft(18).paddingRight(18)
                flex.addItem(postDataBadgeView).width(33.33%)
                flex.addItem(reactionsDataBadgeView).width(33.33%)
                flex.addItem(messagesDataBadgeView).width(33.33%)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}


final class InsightDataBadgeView: UIView {
    private let disposeBag = DisposeBag()
    
    let updownImageView = UIImageView()
    let percentageLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 15))
    let descriptionLabel = Label.create(withFont: R.font.atlasGroteskLight(size: 14))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let toplineView = UIView()
        toplineView.flex.direction(.row).define { (flex) in
            flex.alignItems(.center)
            flex.addItem(updownImageView)
            flex.addItem(percentageLabel).margin(4).grow(1)
        }
        
        self.flex.direction(.column).define { (flex) in
            flex.alignItems(.start)
            flex.addItem(toplineView)
            flex.addItem(descriptionLabel).marginTop(6)
        }
        
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
