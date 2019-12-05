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

class HowItWorksViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var continueButton = makeContinueButton()

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? HowItWorksViewModel else { return }

        continueButton.rx.tap.bind {
            viewModel.gotoGetYourDataScreen()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        let thumbImage = ImageView(image: R.image.howItWorksThumb())
        let blackView = UIView()
        blackView.backgroundColor = .black

        blackView.addSubview(thumbImage)
        thumbImage.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalToSuperview().offset(-40)
            $0.bottom.equalToSuperview().offset(-10)
        }

        view.addSubview(blackView)
        blackView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        super.setupViews()
        showLightBackItem()

        let howItWorksTitle = Label()
        howItWorksTitle.applyBlack(
            text: R.string.phrase.howitworksTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)))

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().height(50%)

            flex.addItem(howItWorksTitle).marginTop(-navigationViewHeight + Size.dh(27))

            flex.addItem(howItWorkContent(part: 1, text: R.string.phrase.howitworksContent1())).marginTop(Size.dh(15))
            flex.addItem(howItWorkContent(part: 2, text: R.string.phrase.howitworksContent2())).marginTop(Size.dh(10))
            flex.addItem(howItWorkContent(part: 3, text: R.string.phrase.howitworksContent3())).marginTop(Size.dh(10))

            flex.addItem(continueButton).position(.absolute).bottom(0).width(100%)
        }
    }
}

extension HowItWorksViewController {
    fileprivate func makeContinueButton() -> Button {
        return SubmitButton(title: R.string.localizable.continue())
    }

    fileprivate func howItWorkContent(part: Int, text: String) -> UIView {
        let partIndexLabel = Label()
        partIndexLabel.applyBlack(
            text: String(part),
            font: R.font.atlasGroteskLight(size: Size.ds(14)))

        let textLabel = Label()
        textLabel.numberOfLines = 0
        textLabel.applyBlack(
            text: text,
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)

        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(partIndexLabel).width(Size.dw(25)).height(Size.dh(25))
            flex.addItem(textLabel)
        }
        return view
    }
}
