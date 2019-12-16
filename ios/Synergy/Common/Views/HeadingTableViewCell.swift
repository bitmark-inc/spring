//
//  HeadingTableViewCell.swift
//  Synergy
//
//  Created by Anh Nguyen on 12/9/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class HeadingTableViewCell: TableViewCell {
    
    lazy var backButton = Button(title: R.string.localizable.backNavigator())
    lazy var accountButton = makeAccountButton()
    lazy var titleLabel = Label.create(withFont: R.font.domaineSansTextLight(size: 36))
    lazy var rightDescriptionLabel = Label.create(withFont: R.font.atlasGroteskRegular(size: 10))
    lazy var subTitleLabel = Label.create(withFont: R.font.domaineSansTextLight(size: 18))
    
    private var backButtonHandler: (() -> Void)? = nil
    
    var rightDescription = "" {
        didSet {
            rightDescriptionLabel.text = rightDescription
            contentView.flex.layout()
        }
    }
    
    var subTitle = "" {
        didSet {
            subTitleLabel.text = subTitle
            contentView.flex.layout()
        }
    }
    
    func setHeading(title: String, color: UIColor?) {
        titleLabel.text = title
        titleLabel.textColor = color
        contentView.flex.layout()
    }
    
    func setBackButtonHandler(_ callback: (() -> Void)?) {
        if callback == nil {
            backButton.flex.height(0)
        } else {
            backButton.flex.height(24)
        }
        
        contentView.flex.layout()
        backButtonHandler = callback
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.flex
            .padding(10, 18, 23, 18)
            .direction(.column).define { (flex) in
                flex.alignItems(.stretch)

                flex.addItem(backButton).height(0)

                flex.addItem().direction(.row).define { (flex) in
                    flex.alignItems(.start)
                    flex.addItem(titleLabel)
                    flex.addItem(rightDescriptionLabel).marginLeft(3)
                }

                flex.addItem(subTitleLabel).marginTop(0)

                flex.addItem(accountButton)
                    .width(20).height(20)
                    .position(.absolute).top(10).right(18)
            }
        
        backButton.titleLabel?.font = R.font.avenir(size: 14)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func backButtonClicked(sender: UIButton) {
        self.backButtonHandler?()
    }
}

extension HeadingTableViewCell {
    fileprivate func makeAccountButton() -> Button {
        let button = SubmitButton()
        button.setImage(R.image.account_icon(), for: .normal)
        return button
    }
}
