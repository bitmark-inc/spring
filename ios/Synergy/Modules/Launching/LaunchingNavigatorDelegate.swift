//
//  LaunchingNavigatorDelegate.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa
import FlexLayout

protocol LaunchingNavigatorDelegate: ViewController {
    func navigate()
}

extension LaunchingNavigatorDelegate {
    func navigate() {
        if UserDefaults.standard.FBArchiveCreatedAt != nil {
            loadingState.onNext(.hide)
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
                    loadingState.onNext(.hide)
                    _ = ErrorAlert.showAuthenticationRequiredAlert { [weak self] in
                        self?.navigate()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    fileprivate func prepareAndGotoNext(account: Account?) throws -> Completable {
        if let account = account {
            Global.current.account = account
            try RealmConfig.setupDBForCurrentAccount()

            FbmAccountDataEngine.rx.fetchCurrentFbmAccount()
                .subscribe(onSuccess: {  [weak self] (_) in
                    self?.checkArchivesStatusToNavigate()

                }, onError: { [weak self] (error) in
                    loadingState.onNext(.hide)
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
            loadingState.onNext(.hide)
            gotoSignInWallScreen()
        }

        return Completable.empty()
    }

    fileprivate func checkArchivesStatusToNavigate() {
        FbmAccountService.fetchOverallArchiveStatus()
            .subscribe(onSuccess: { [weak self] (archiveStatus) in
                guard let self = self else { return }
                loadingState.onNext(.hide)
                Global.current.userDefault?.latestArchiveStatus = archiveStatus?.rawValue
                self.navigateWithArchiveStatus(archiveStatus)

            }, onError: { [weak self] (error) in
                loadingState.onNext(.hide)
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
            switch archiveStatus {
            case .processed:
                gotoMainScreen()
            default:
                gotoDataAnalyzingScreen()
            }
        } else {
            gotoSignInWallScreen()
        }
    }
}

// MARK: - Navigator
extension LaunchingNavigatorDelegate {
    fileprivate func gotoSignInWallScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(.downloadData)
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDataRequestedWithCheckButtonScreen() {
        let viewModel = DataRequestedViewModel(.checkRequestedData)
        navigator.show(segue: .dataRequested(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }

    fileprivate func gotoDataAnalyzingScreen() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}
