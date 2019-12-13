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
    lazy var webView = makeWebView()

    static let fbURL = "https://m.facebook.com"
    var cachedRequestHeader: [String: String]?
    var fbScripts: [FBScript]?
    lazy var archivePageScript = {
        fbScripts?.first(where: { $0.name == FBPage.archive.rawValue })
    }()

    var checkLoginFailedDisposable: Disposable?

    lazy var thisViewModel = {
        return self.viewModel as! RequestDataViewModel
    }()

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
                loadingState.onNext(.hide)

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
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                    self.gotoDataAnalyzing()
                default:
                    break
                }
            }).disposed(by: disposeBag)
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

    // MARK: Setup Views
    override func setupViews() {
        super.setupViews()

        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
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
            Global.log.info("[start] evaluateJS for \(pageScript.name)")
            Global.log.info("Result: \(result ?? "")")
            if let error = error { Global.log.info("Error: \(error)") }

            guard error == nil, let result = result as? Bool, result else {
                let nextIndex = index + 1
                if nextIndex < numberOfScript {
                    self.evaluateJS(index: nextIndex)
                }

                return
            }

            guard let facePage = FBPage(rawValue: pageScript.name) else { return }
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
            .subscribe(onError: { (error) in
                Global.log.error(error)
            }, onCompleted: {
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
            }, onError: { (error) in
                Global.log.error(error)
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
                }, onError: {(error) in
                    Global.log.error(error)
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
}
