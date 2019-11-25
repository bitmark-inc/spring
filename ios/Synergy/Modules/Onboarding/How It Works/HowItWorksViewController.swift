//
//  HowItWorksViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class HowItWorksViewController: ViewController {

    // MARK: - Properties
    var continueButton: SubmitButton!

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? HowItWorksViewModel else { return }

        continueButton.rx.tap.bind {
            viewModel.gotoGetYourDataScreen()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let thumbImage = ImageView(image: R.image.howItWorksThumb())
        thumbImage.contentMode = .scaleAspectFill

        view.addSubview(thumbImage)
        thumbImage.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        let howItWorksTitle = Label()
        howItWorksTitle.applyBlack(
            text: R.string.phrase.howitworksTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36))
        )

        func howItWorkContent(part: Int, text: String) -> UIView {
            let partIndexLabel = Label()
            partIndexLabel.applyBlack(
                text: String(part),
                font: R.font.atlasGroteskLight(size: Size.ds(14))
            )
            partIndexLabel.contentMode = .top

            let textLabel = Label()
            textLabel.numberOfLines = 0
            textLabel.applyBlack(
                text: text,
                font: R.font.atlasGroteskLight(size: Size.ds(18)),
                lineHeight: 1.2
            )

            let view = UIView()
            view.flex.direction(.row).define { (flex) in
                flex.addItem(partIndexLabel).width(Size.dw(25))
                flex.addItem(textLabel)
            }
            return view
        }

        continueButton = SubmitButton(title: R.string.localizable.continue())
        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().height(50%)

            flex.addItem(howItWorksTitle).marginTop(10).width(100%)

            flex.addItem(howItWorkContent(part: 1, text: R.string.phrase.howitworksContent1())).marginTop(Size.dh(20))
            flex.addItem(howItWorkContent(part: 2, text: R.string.phrase.howitworksContent2())).marginTop(Size.dh(10))
            flex.addItem(howItWorkContent(part: 3, text: R.string.phrase.howitworksContent3())).marginTop(Size.dh(10))

            continueButton.flex.position(.absolute).bottom(0).width(100%)
            flex.addItem(continueButton)
        }
    }
}
