//
//  StreamViewController.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa

class StreamViewController: ViewController {

    // MARK: - Properties
    fileprivate lazy var subTitleButton = makeSubTitleLabel()
    fileprivate lazy var streamDescLabel = makeStreamDescLabel()

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? StreamViewModel else { return }

        viewModel.signOutResultSubject
            .subscribe(onNext: { (event) in
                switch event {
                case .error(let error):
                    Global.log.error(error)
                case .completed:
                    Global.log.info("[done] signOut")
                    viewModel.moveToOnboardingFlow()
                default:
                    break
                }
            }).disposed(by: disposeBag)

        subTitleButton.rx.tap.bind {
            viewModel.signOut()
        }.disposed(by: disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let titleScreen = Label()
        titleScreen.applyBlack(
            text: R.string.localizable.streams().localizedUppercase,
            font: R.font.domaineSansTextRegular(size: Size.ds(36)),
            lineHeight: 1.06, level: 2)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(titleScreen).marginTop(-17)
            flex.addItem(subTitleButton).marginTop(2)
            flex.addItem(streamDescLabel).marginTop(36)
        }
    }
}

extension StreamViewController {
    func makeSubTitleLabel() -> Button {
        let button = Button()
        button.contentHorizontalAlignment = .left
        button.applyBlack(
            title: R.string.localizable.comingSoon().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(18)))
        return button
    }

    func makeStreamDescLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: R.string.localizable.comingSoonDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)
        label.numberOfLines = 0
        return label
    }
}
