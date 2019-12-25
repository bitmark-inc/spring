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

    static let fbURL = "https://m.facebook.com"
    var cachedRequestHeader: [String: String]?
    var fbScripts: [FBScript]?
    lazy var archivePageScript = {
        fbScripts?.first(where: { $0.name == FBPage.archive.rawValue })
    }()

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
                self?.observeAutomatingStatus()

                guard let self = self, let urlRequest = URLRequest(urlString: Self.fbURL) else { return }
                self.fbScripts = fbScripts
                self.webView.load(urlRequest)
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
                    self.gotoDataAnalyzing()
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }

    fileprivate func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    fileprivate func errorWhenRequestFBScript(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.requestData())
    }

    fileprivate func errorWhenSignUpAndSubmitArchive(error: Error) {
        guard !AppError.errorByNetworkConnection(error) else { return }

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
        guard let fbScripts = fbScripts else { return }

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
            case .accountPicking:
                self.runJS(accountPickingScript: pageScript)
            }
        }
    }
}

// MARK: - Execute JS for FB Page
extension RequestDataViewController {
    fileprivate func checkIsArchivePage() -> Observable<Void> {
        return Observable<Void>.create { (event) -> Disposable in
            guard let detection = self.archivePageScript?.detection else {
                return Disposables.create()
            }

            self.webView.evaluateJavaScript(detection) { (result, error) in
                guard error == nil, let isArchivePage = result as? Bool, isArchivePage else {
                    event.onError(AppError.fbArchivePageIsNotReady)
                    return
                }
                event.onCompleted()
            }

            return Disposables.create()
        }
    }

    fileprivate func doMissionInArchivePage() {
        checkIsArchivePage()
            .retry(.delayed(maxCount: 1000, time: 0.5))
            .subscribe(onError: { [weak self] (error) in
                Global.log.error(error)
                self?.automatingStatusRelay.accept(false)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                Global.log.info("[start] evaluateJS for archive")
                switch self.thisViewModel.mission {
                case .requestData:
                    self.runJSToCreateDataArchive()
                case .downloadData:
                    self.runJSTodownloadFBArchiveIfExist()
                default:
                    return
                }
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
            self.gotoDataRequested()
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

    fileprivate func runJS(saveDeviceScript: FBScript) {
        guard let notNowAction = saveDeviceScript.script(for: .notNow) else { return }
        webView.evaluateJavaScript(notNowAction)
    }

    fileprivate func runJS(newFeedScript: FBScript) {
        guard let gotoSettingsPageAction = newFeedScript.script(for: .goToSettingsPage) else { return }
        webView.evaluateJavaScript(gotoSettingsPageAction)
    }

    fileprivate func runJS(settingsScript: FBScript) {
        guard let gotoArchivePageAction = settingsScript.script(for: .goToArchivePage) else { return }

        webView.evaluateJavaScript(gotoArchivePageAction) { [weak self] (_, error) in
            guard let self = self else { return }
            guard error == nil else {
                Global.log.error(error)
                return
            }
            self.doMissionInArchivePage() // it's not trigger webView#didFinish function
        }
    }

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
        guard let viewModel = viewModel as? RequestDataViewModel else { return }
        let dataRquestedViewModel = DataRequestedViewModel(viewModel.mission)
        navigator.show(segue: .dataRequested(viewModel: dataRquestedViewModel), sender: self)
    }

    func gotoDataAnalyzing() {
        let viewModel = DataAnalyzingViewModel()
        navigator.show(segue: .dataAnalyzing(viewModel: viewModel), sender: self)
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
