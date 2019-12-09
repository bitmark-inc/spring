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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // NOTE: For first demo, make quick Onboarding Flow
        AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (account) in
                guard let self = self else { return }

                print("---------onSuccess--------------LOG THUYEN_____________________")
                Global.current.account = account

                if Global.current.account != nil {
                    self.gotoMainScreen()
                } else {
                    self.gotoSignInWallScreen()
                }
            }, onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)

        return
        // END

        if UserDefaults.standard.isCreatingFBArchive {
            gotoDownloadFBArchiveScreen()
            return
        }

        AccountService.rx.existsCurrentAccount()
            .observeOn(MainScheduler.instance)
            .flatMapCompletable { [weak self] in
                guard let self = self else { return Completable.never() }
                return try self.prepareAndGotoNext(account: $0)
            }
            .subscribe(onError: { (error) in
                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func prepareAndGotoNext(account: Account?) throws -> Completable {
        if let account = account {
            Global.current.account = account
            try RealmConfig.setupDBForCurrentAccount()

            FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .subscribe(onSuccess: {  [weak self] (_) in
                    guard let self = self else { return }
                    // TODO: Check if finish generating data's insights
                    self.gotoDataGeneratingScreen()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    // is not FBM's Account => link to HowItWorks
                    if let error = error as? ServerAPIError {
                        switch error.code {
                        case .AccountNotFound:
                             self.gotoHowItWorksScreen()
                            return
                        default:
                            break
                        }
                    }

                    guard !AppError.errorByNetworkConnection(error) else { return }
                    Global.log.error(error)
                    self.showErrorAlertWithSupport(message: R.string.error.system())
                })
                .disposed(by: disposeBag)
        } else {
            gotoSignInWallScreen()
        }

        return Completable.empty()
    }

    override func setupViews() {
        setupBackground(image: R.image.onboardingSplash())
        super.setupViews()

        contentView.backgroundColor = .clear

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.applyLight(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(150)))
        titleScreen.adjustsFontSizeToFitWidth = true

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.applyLight(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            lineHeight: 1.1)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(titleScreen).marginTop(Size.dh(380)).width(100%)
                flex.addItem(descriptionLabel).marginTop(Size.dh(10))
            }
    }
}

// MARK: - Navigator
extension LaunchingViewController {
    func gotoSignInWallScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self)
    }

    func gotoHowItWorksScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel), sender: self)
    }

    func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(.downloadData)
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self)
    }

    func gotoDataGeneratingScreen() {
        let viewModel = DataGeneratingViewModel()
        navigator.show(segue: .dataGenerating(viewModel: viewModel), sender: self)
    }

    func gotoSignInScreen() {

    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .auto))
    }
}
