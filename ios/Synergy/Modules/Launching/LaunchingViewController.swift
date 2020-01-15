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

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigate()
    }

    fileprivate func navigate() {
        if UserDefaults.standard.FBArchiveCreatedAt != nil {
            if Global.current.didUserTapNotification {
                Global.current.didUserTapNotification = false
                gotoDownloadFBArchiveScreen()
            } else {
                gotoDataRequestedWithCheckButtonScreen()
            }
        } else {
            AccountService.rx.existsCurrentAccount()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] (account) in
                    guard let self = self else { return }
                    if let account = account {
                        AccountService.registerIntercom(for: account.getAccountNumber())
                        SettingsBundle.setAccountNumber(accountNumber: account.getAccountNumber())
                    }

                    do {
                        _ = try self.prepareAndGotoNext(account: account).subscribe()
                    } catch {
                        Global.log.error(error)
                    }

                }, onError: { (error) in
                    _ = ErrorAlert.showAuthenticationRequiredAlert { [weak self] in
                        self?.navigate()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    func prepareAndGotoNext(account: Account?) throws -> Completable {
        if let account = account {
            Global.current.account = account
            try RealmConfig.setupDBForCurrentAccount()

            FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .subscribe(onSuccess: {  [weak self] (_) in
                    self?.checkArchivesStatusToNavigate()

                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    guard !AppError.errorByNetworkConnection(error) else { return }
                    guard !self.showIfRequireUpdateVersion(with: error) else { return }

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

                    Global.log.error(error)
                    self.showErrorAlertWithSupport(message: R.string.error.system())
                })
                .disposed(by: disposeBag)
        } else {
            gotoSignInWallScreen()
        }

        return Completable.empty()
    }

    fileprivate func checkArchivesStatusToNavigate() {
        FbmAccountService.fetchOverallArchiveStatus()
            .subscribe(onSuccess: { [weak self] (archiveStatus) in
                guard let self = self else { return }
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
                self.navigateWithArchiveStatus(archiveStatus)

            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                if AppError.errorByNetworkConnection(error) {
                    let archiveStatus = ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? "")
                    self.navigateWithArchiveStatus(archiveStatus)
                    return
                }

                guard !self.showIfRequireUpdateVersion(with: error) else { return }

                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.system())
            })
            .disposed(by: disposeBag)
    }

    fileprivate func navigateWithArchiveStatus(_ archiveStatus: ArchiveStatus?) {
        if let archiveStatus = archiveStatus {
            if InsightDataEngine.existsAdsCategories() {
                switch archiveStatus {
                case .processed:
                    gotoMainScreen()
                default:
                    gotoDataAnalyzingScreen()
                }
            } else {
                let viewModel = GetYourDataViewModel(missions: [.getCategories])
                navigator.show(segue: .getYourData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
            }
        } else {
            gotoSignInWallScreen()
        }
    }

    override func setupViews() {
        setupBackground(backgroundView: ImageView(image: R.image.onboardingSplash()))
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
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self, transition: .replace(type: .none))
    }

    func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(missions: [.downloadData])
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .none))
    }
    
    func gotoDataRequestedWithCheckButtonScreen() {
        let viewModel = DataRequestedViewModel(.checkRequestedData)
        navigator.show(segue: .dataRequested(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    func gotoDataAnalyzingScreen() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}
