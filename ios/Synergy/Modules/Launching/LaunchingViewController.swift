//
//  LaunchingViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa
import FlexLayout

class LaunchingViewController: ViewController {

    override func bindViewModel() {
        super.bindViewModel()

        AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .do(onSuccess: { Global.current.account = $0 })
            .flatMapCompletable { [weak self] in
                guard let self = self else { return Completable.never() }
                return try self.prepareAndGotoNext(account: $0)
        }
        .subscribe(
            onError: { (error) in
                Global.log.error(error)
            })
        .disposed(by: disposeBag)
    }

    func prepareAndGotoNext(account: Account?) throws -> Completable {
        guard let viewModel = viewModel as? LaunchingViewModel else { return Completable.never() }

        if let account = account {
            Global.current.account = account

            try RealmConfig.setupDBForCurrentAccount()
            viewModel.gotoHowItWorksScreen()
        } else {
            viewModel.gotoSignInWallScreen()
        }
        return Completable.empty()
    }

    override func setupViews() {
        setupBackground(image: R.image.onboardingSplash())
        super.setupViews()

        // *** Setup subviews ***
        let titleScreen = LightLabel()
        titleScreen.font = R.font.domaineSansTextRegular(size: Size.ds(150))
        titleScreen.text = R.string.phrase.launchName().localizedUppercase
        titleScreen.adjustsFontSizeToFitWidth = true

        let descriptionLabel = LightDesriptionLabel(text: R.string.phrase.launchDescription())
        descriptionLabel.font = R.font.atlasGroteskRegular(size: Size.ds(22))
        descriptionLabel.lineHeightMultiple(1.1)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem(titleScreen).marginTop(50%).width(100%)
            flex.addItem(descriptionLabel).marginTop(Size.dh(10))
        }
    }
}
