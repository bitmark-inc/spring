//
//  RequestDataViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import FlexLayout
import WebKit
import RxSwift
import RxCocoa
import RxSwiftExt

class RequestDataViewController: ViewController {

    // MARK: - Properties
    lazy var guideView = makeGuideView()
    lazy var guideTextLabel = makeGuideTextLabel()
    lazy var automatingCoverView = makeCoverView()
    lazy var webView = makeWebView()

    var undoneMissions = [Mission]()
    static let fbURL = "https://m.facebook.com"
    var cachedRequestHeader: [String: String]?
    var fbScripts = [FBScript]()
    lazy var archivePageScript = fbScripts.find(.archive)

    let automatingStatusRelay = BehaviorRelay<Bool>(value: true)

    var checkLoginFailedDisposable: Disposable?

    lazy var thisViewModel = {
        return self.viewModel as! RequestDataViewModel
    }()

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func bindViewModel() {
        super.bindViewModel()

        webView.navigationDelegate = self

        guard let viewModel = viewModel as? RequestDataViewModel else { return }

        undoneMissions = viewModel.missions

        viewModel.fbScriptResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenRequestFBScript(error: error)
                default:
                    break
                }
            }).disposed(by: disposeBag)

        loadingState.onNext(.loading)
        viewModel.fbScriptsRelay
            .filterEmpty()
            .subscribe(onNext: { [weak self] (fbScripts) in
                guard let self = self else { return }
                self.observeAutomatingStatus()
                self.fbScripts = fbScripts
                self.loadWebView()
            })
            .disposed(by: disposeBag)

        viewModel.signUpAndSubmitArchiveResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenSignUpAndSubmitArchive(error: error)
                case .completed:
                    Global.log.info("[done] SignUpAndSubmitArchive")
                    UserDefaults.standard.FBArchiveCreatedAt = nil
                    self.clearAllNotifications()
                    self.gotoDataAnalyzingScreen()
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }

    fileprivate func loadWebView() {
        guard let urlRequest = URLRequest(urlString: Self.fbURL) else { return }
        webView.load(urlRequest)
    }

    fileprivate func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    fileprivate func errorWhenRequestFBScript(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.requestData())
    }

    fileprivate func errorWhenSignUpAndSubmitArchive(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }
        guard !showIfRequireUpdateVersion(with: error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
    }

    lazy var backgroundView = UIView()

    // MARK: Setup Views
    override func setupViews() {
        setupBackground(backgroundView: backgroundView)
        super.setupViews()

        contentView.flex
            .direction(.column)
            .define { (flex) in
                flex.addItem(guideView)
                flex.addItem().grow(1).define { (flex) in
                    flex.addItem(webView).width(100%).height(100%)
                    flex.addItem(automatingCoverView)
                        .position(.absolute).top(0).left(0)
                        .width(100%).height(100%)
                }
        }
    }

    fileprivate func observeAutomatingStatus() {
        automatingStatusRelay
            .subscribe(onNext: { [weak self] (isAutomating) in
                guard let self = self else { return }
                if isAutomating {
                    self.guideView.backgroundColor = ColorTheme.cognac.color
                    self.guideTextLabel.setText(nil)
                    self.automatingCoverView.isHidden = false
                    self.backgroundView.backgroundColor = ColorTheme.cognac.color
                } else {
                    self.guideView.backgroundColor = ColorTheme.internationalKleinBlue.color
                    self.guideTextLabel.setText(R.string.phrase.guideRequiredHelp().localizedUppercase)
                    self.automatingCoverView.isHidden = true
                    self.guideTextLabel.flex.markDirty()
                    self.guideView.flex.layout()
                    self.backgroundView.backgroundColor = ColorTheme.internationalKleinBlue.color
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - WKNavigationDelegate
extension RequestDataViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse else { return }

        guard let contentType = response.allHeaderFields["Content-Type"] as? String,
            contentType == "application/zip",
            let cachedRequestHeader = cachedRequestHeader,
            let archiveURL = response.url
            else {
                decisionHandler(.allow)
                return
        }
        
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ (cookies) in
            let rawCookie = cookies.compactMap { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            
            self.thisViewModel.signUpAndSubmitFBArchive(headers: cachedRequestHeader, archiveURL: archiveURL, rawCookie: rawCookie)
        })

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url, url.absoluteString.contains("download/file") {
            cachedRequestHeader = navigationAction.request.allHTTPHeaderFields
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingState.onNext(.hide)

        // check & run JS for determined FB pages; start checking from index 0
        evaluateJS(index: 0)
    }

    fileprivate func evaluateJS(index: Int) {
        let numberOfScript = fbScripts.count
        let pageScript = fbScripts[index]

        webView.evaluateJavaScript(pageScript.detection) { (result, error) in
            Global.log.info("[start] evaluateJS for \(pageScript.name): \(result ?? "")")
            if let error = error { Global.log.info("Error: \(error)") }

            guard error == nil, let result = result as? Bool, result else {
                let nextIndex = index + 1
                if nextIndex < numberOfScript {
                    self.evaluateJS(index: nextIndex)
                } else {
                    // is not the page in all detection pages, show required help
                    self.automatingStatusRelay.accept(false)
                }

                return
            }

            guard let facePage = FBPage(rawValue: pageScript.name) else { return }
            self.automatingStatusRelay.accept(true)

            switch facePage {
            case .login:
                self.runJS(loginScript: pageScript)
            case .saveDevice:
                self.runJS(saveDeviceScript: pageScript)
            case .newFeed:
                self.checkLoginFailedDisposable?.dispose()
                self.runJS(newFeedScript: pageScript)
            case .settings:
                self.runJS(settingsScript: pageScript)
            case .reauth:
                self.runJS(reAuthScript: pageScript)
            case .archive:
                break
            case .adsPreferences:
                self.runJS(adsPreferencesScript: pageScript)
            case .demographics:
                self.runJS(demographicsScript: pageScript)
            case .behaviors:
                self.runJS(behaviorsScript: pageScript)
            case .accountPicking:
                self.runJS(accountPickingScript: pageScript)
            }
        }
    }
}

// MARK: - Execute JS for FB Page
extension RequestDataViewController {
    fileprivate func checkIsPage(script: FBScript) -> Observable<Void> {
        return Observable<Void>.create { (event) -> Disposable in
            let detection = script.detection

            self.webView.evaluateJavaScript(detection) { (result, error) in
                guard error == nil, let isRequiredPage = result as? Bool, isRequiredPage else {
                    event.onError(AppError.fbRequiredPageIsNotReady)
                    return
                }
                event.onCompleted()
            }

            return Disposables.create()
        }
    }

    fileprivate func doMissionInArchivePage() {
        guard let archivePageScript = archivePageScript else { return }
        checkIsPage(script: archivePageScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                Global.log.info("[start] evaluateJS for archive")

                let missions = self.thisViewModel.missions
                if missions.contains(.requestData) {
                    self.runJSToCreateDataArchive()
                } else if missions.contains(.downloadData) {
                    self.runJSTodownloadFBArchiveIfExist()
                }

            })
            .disposed(by: disposeBag)
    }

    fileprivate func doMissionInAdsPage() {
        guard let adsPageScript = fbScripts.find(.adsPreferences) else { return }
        checkIsPage(script: adsPageScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                Global.log.info("[start] evaluateJS for adsPreferences")

                self.runJS(adsPreferencesScript: adsPageScript)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func runJSToCreateDataArchive() {
        guard let archivePageScript = archivePageScript,
            let selectRequestTabAction = archivePageScript.script(for: .selectRequestTab),
            let selectJSONOptionAction = archivePageScript.script(for: .selectJSONOption),
            let selectHighResolutionOptionAction = archivePageScript.script(for: .selectHighResolutionOption),
            let createFileAction = archivePageScript.script(for: .createFile)
            else {
                return
        }

        let action = [selectRequestTabAction, selectJSONOptionAction, selectHighResolutionOptionAction, createFileAction].joined()

        webView.evaluateJavaScript(action) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.fbRequestData())
                return
            }

            Global.log.info("[done] createFBArchive")
            UserDefaults.standard.FBArchiveCreatedAt = Date()

            self.undoneMissions.removeFirst()

            if self.undoneMissions.isEmpty {
                self.gotoDataRequested()
            } else {
                self.loadWebView()
            }
        }
    }

    fileprivate func runJSTodownloadFBArchiveIfExist() {
        guard let isCreatingFileAction = archivePageScript?.script(for: .isCreatingFile) else {
            return
        }

        webView.evaluateJavaScript(isCreatingFileAction) { [weak self] (result, error) in
            guard let self = self else { return }
            guard error == nil, let isCreatingFile = result as? Bool else {
                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.fbRequestData())
                return
            }

            isCreatingFile ?
                self.gotoDataRequested() :
                self.runJSTodownloadFBArchive()
        }
    }

    func runJSTodownloadFBArchive() {
        guard let archivePageScript = archivePageScript,
            let selectDownloadTabAction = archivePageScript.script(for: .selectDownloadTab),
            let selectJSONOptionAction = archivePageScript.script(for: .downloadFirstFile)
            else {
                return
        }

        let action = [selectDownloadTabAction, selectJSONOptionAction].joined()

        webView.evaluateJavaScript(action) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                self.showErrorAlertWithSupport(message: R.string.error.fbDownloadData())
                return
            }
        }
    }

    // MARK: - Login Script
    fileprivate func runJS(loginScript: FBScript) {
        guard let viewModel = viewModel as? RequestDataViewModel,
            let loginAction = loginScript.script(for: .login),
            let checkLoginFailedDetection = loginScript.script(for: .isLogInFailed)
            else {
                return
        }

        checkLoginFailedDisposable = checkIsLoginFailed(detection: checkLoginFailedDetection)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onNext: { [weak self] (_) in
                Global.log.info("[start] loginFailed detection")
                self?.showIncorrectCredentialAlert()
            }, onError: { (error) in
                Global.log.error(error)
            })

        Single.just((username: viewModel.login, password: viewModel.password))
            .flatMap { (credential) -> Single<(username: String, password: String)> in
                guard credential.username != nil, credential.password != nil else {
                    return KeychainStore.getFBCredentialToKeychain()
                }
                return Single.just((username: credential.username!, password: credential.password!))
            }
            .do(onSuccess: { viewModel.login = $0.username; viewModel.password = $0.password })
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (credential) in
                self?.webView.evaluateJavaScript(loginAction
                    .replacingOccurrences(of: "%username%", with: credential.username)
                    .replacingOccurrences(of: "%password%", with: credential.password)
                )
            }, onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
            })
            .disposed(by: self.disposeBag)
    }

    fileprivate func checkIsLoginFailed(detection: String) -> Observable<Void> {
        return Observable<Void>.create { (event) -> Disposable in
            self.webView.evaluateJavaScript(detection) { (result, error) in
                guard error == nil, let isLoginFailed = result as? Bool, isLoginFailed else {
                    event.onError(AppError.loginFailedIsNotDetected)
                    return
                }
                event.onNext(())
                event.onCompleted()
            }

            return Disposables.create()
        }
    }

    fileprivate func showIncorrectCredentialAlert() {
        let alertController = UIAlertController(
            title: R.string.error.fbCredentialTitle(),
            message: R.string.error.fbCredentialMessage(),
            preferredStyle: .alert)

        alertController.addAction(title: R.string.localizable.ok(), style: .default) { (_) in
            let cookieJar = HTTPCookieStorage.shared
            cookieJar.cookies?.forEach { cookieJar.deleteCookie($0) }
            Navigator.default.pop(sender: self)
        }

        alertController.show()
    }

    // MARK: saveDevice Script
    fileprivate func runJS(saveDeviceScript: FBScript) {
        guard let notNowAction = saveDeviceScript.script(for: .notNow) else { return }
        webView.evaluateJavaScript(notNowAction)
    }

    // MARK: newFeed Script
    fileprivate func runJS(newFeedScript: FBScript) {
        guard let gotoSettingsPageAction = newFeedScript.script(for: .goToSettingsPage) else { return }
        webView.evaluateJavaScript(gotoSettingsPageAction)
    }

    // MARK: Settings Script
    fileprivate func runJS(settingsScript: FBScript) {
        guard let doingMission = undoneMissions.first else { return }

        switch doingMission {
        case .requestData, .checkRequestedData, .downloadData:
            guard let goToArchivePageAction = settingsScript.script(for: .goToArchivePage) else { return }

            webView.evaluateJavaScript(goToArchivePageAction) { [weak self] (_, error) in
                guard let self = self else { return }
                guard error == nil else {
                    Global.log.error(error)
                    return
                }
                self.doMissionInArchivePage() // it's not trigger webView#didFinish function
            }
        case .getCategories:
            guard let goToAdsPreferencesPageAction = settingsScript.script(for: .goToAdsPreferencesPage) else { return }

            webView.evaluateJavaScript(goToAdsPreferencesPageAction) { [weak self] (_, error) in
                guard let self = self else { return }
                guard error == nil else {
                    Global.log.error(error)
                    return
                }

                self.doMissionInAdsPage() // it's not trigger webView#didFinish function
            }
        }
    }

    // MARK: AdsPreferences Script
    fileprivate func runJS(adsPreferencesScript: FBScript) {
        guard let goToYourInformationPageAction = adsPreferencesScript.script(for: .goToYourInformationPage)
            else {
                return
        }

        webView.evaluateJavaScript(goToYourInformationPageAction) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                return
            }

            guard let demographicsPageScript = self.fbScripts.find(.demographics) else { return }
            self.runJS(demographicsScript: demographicsPageScript)
        }
    }

    // MARK: Demographics Script
    fileprivate func runJS(demographicsScript: FBScript) {
        checkIsPage(script: demographicsScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
                }, onCompleted: { [weak self] in
                    guard let self = self else { return }
                    Global.log.info("[start] evaluateJS for demographics")

                    guard let goToBehaviorsPageAction = demographicsScript.script(for: .goToBehaviorsPage)
                        else {
                            return
                    }

                    self.webView.evaluateJavaScript(goToBehaviorsPageAction) { [weak self] (_, error) in
                        guard let self = self else { return }
                        guard error == nil else {
                            Global.log.error(error)
                            return
                        }

                        guard let behaviorsScript = self.fbScripts.find(.behaviors) else { return }
                        self.runJS(behaviorsScript: behaviorsScript)
                    }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Behaviors Script
    fileprivate func runJS(behaviorsScript: FBScript) {
        checkIsPage(script: behaviorsScript)
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
                }, onCompleted: { [weak self] in
                    guard let self = self else { return }
                    Global.log.info("[start] evaluateJS for behavior")

                    guard let getCategoriesAction = behaviorsScript.script(for: .getCategories)
                        else {
                            return
                    }

                    self.webView.evaluateJavaScript(getCategoriesAction) { [weak self] (adsCategories, error) in
                        guard error == nil else {
                            Global.log.error(error)
                            return
                        }

                        guard let self = self,
                            let adsCategories = adsCategories as? [String] else { return }

                        if Global.current.account == nil {
                            UserDefaults.standard.fbCategoriesInfo = adsCategories
                            self.gotoDataRequested()
                        } else {
                            self.thisViewModel.storeAdsCategoriesInfo(adsCategories)
                                .subscribe(onCompleted: { [weak self] in
                                    self?.navigateWithArchiveStatus(
                                        ArchiveStatus(rawValue: Global.current.userDefault?.latestArchiveStatus ?? ""))
                                }, onError: { [weak self] (error) in
                                    Global.log.error(error)
                                    self?.showErrorAlertWithSupport(message: R.string.error.system())
                                })
                                .disposed(by: self.disposeBag)
                        }
                    }
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
            gotoHowItWorksScreen()
        }
    }


    // MARK: ReAuth Script
    fileprivate func runJS(reAuthScript: FBScript) {
        guard let viewModel = viewModel as? RequestDataViewModel,
            let reauthAction = reAuthScript.script(for: .reauth)
            else {
                return
        }

        viewModel.getFBCredential()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (credential) in
                self?.webView.evaluateJavaScript(reauthAction
                    .replacingOccurrences(of: "%password%", with: credential.password)
                )
                }, onError: { [weak self] (error) in
                    Global.log.error(error)
                    self?.automatingStatusRelay.accept(false)
                })
            .disposed(by: self.disposeBag)
    }

    // MARK: Account Picking Script
    fileprivate func runJS(accountPickingScript: FBScript) {
        guard let pickAnotherAction = accountPickingScript.script(for: .pickAnother)
            else {
                return
        }

        webView.evaluateJavaScript(pickAnotherAction)
    }
}

// MARK: - Navigator
extension RequestDataViewController {
   func gotoDataRequested() {
        guard let viewModel = viewModel as? RequestDataViewModel,
            let mainMission = viewModel.missions.first else { return }
        let dataRquestedViewModel = DataRequestedViewModel(mainMission)
        navigator.show(segue: .dataRequested(viewModel: dataRquestedViewModel), sender: self)
    }

    func gotoDataAnalyzingScreen() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self)
    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs, sender: self, transition: .replace(type: .none))
    }

    func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self, transition: .replace(type: .none))
    }
}

// MARK: - Make UI
extension RequestDataViewController {
    fileprivate func makeWebView() -> WKWebView {
        return WKWebView()
    }

    fileprivate func makeGuideView() -> UIView {
        let view = UIView()
        view.flex.height(50).justifyContent(.center).define { (flex) in
            flex.addItem(guideTextLabel).alignSelf(.center)
        }
        view.backgroundColor = ColorTheme.cognac.color
        return view
    }

    fileprivate func makeGuideTextLabel() -> Label {
        let label = Label()
        label.applyLight(
            text: "",
            font: R.font.atlasGroteskRegular(size: 18),
            lineHeight: 1.2)
        return label
    }

    fileprivate func makeCoverView() -> UIView {
        let view = UIView()

        let label = Label()
        label.apply(
            text: R.string.phrase.guideAutomating().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(40)),
            colorTheme: .black)
        label.numberOfLines = 0

        view.flex
            .backgroundColor(themeService.attrs.blurCoverColor)
            .justifyContent(.center)
            .define { (flex) in
                flex.addItem(label).marginLeft(22)
                flex.addItem().height(20)
        }
        view.isHidden = true
        return view
    }
}
