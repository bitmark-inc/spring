//
//  DataAnalyzingViewController.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import UserNotifications
import OneSignal

class DataAnalyzingViewController: ViewController {

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let thumbImage = ImageView(image: R.image.hedgehogs())
        thumbImage.contentMode = .scaleAspectFill

        view.addSubview(thumbImage)
        thumbImage.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.47)
        }

        super.setupViews()

        let dataGeneratingTitle = Label()
        dataGeneratingTitle.adjustsFontSizeToFitWidth = true
        dataGeneratingTitle.applyBlack(
            text: R.string.phrase.dataAnalyzingScreenTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)),
            lineHeight: 1.06)

        let dataGeneratingDesc = Label()
        dataGeneratingDesc.numberOfLines = 0
        dataGeneratingDesc.applyBlack(
            text: R.string.phrase.dataAnalyzingDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem().height(47%)

                flex.addItem(dataGeneratingTitle).marginTop(Size.dh(27))
                flex.addItem(dataGeneratingDesc).marginTop(Size.dh(15))
            }
    }
}
