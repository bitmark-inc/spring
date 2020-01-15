//
//  IncreasePrivacyViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import Foundation
import FlexLayout
import WebKit
import RxSwift
import RxCocoa

class IncreasePrivacyViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var webView = makeWebView()
    lazy var titleView = makeTitleView()
    lazy var shareButton = makeShareButton()
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorTheme.cognac.color
        return view
    }()

    lazy var thisViewModel = {
        return self.viewModel as! IncreasePrivacyViewModel
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func bindViewModel() {
        super.bindViewModel()
        loadWebView()
    }

    fileprivate func loadWebView() {
        let guideURLRequest = URLRequest(url: thisViewModel.increasePrivacyOption.guideURL)
        loadingState.onNext(.loading)
        webView.load(guideURLRequest)
    }

    // MARK: Setup Views
    override func setupViews() {
        setupBackground(backgroundView: backgroundView)
        super.setupViews()

        contentView.flex
            .direction(.column)
            .define { (flex) in
                flex.addItem(titleView).padding(OurTheme.paddingInset).marginBottom(12)
                flex.addItem(webView).grow(1)
            }
    }
}

// MARK: - WKNavigationDelegate
extension IncreasePrivacyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingState.onNext(.hide)
    }
}

// MARK: - Setup Views
extension IncreasePrivacyViewController {
    fileprivate func makeWebView() -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = self
        return webView
    }

    fileprivate func makeTitleView() -> UIView {
        let view = UIView()

        view.flex.direction(.row)
            .define { (flex) in
                flex.addItem(makeLightBackItem())
                flex.addItem(makeScreenTitle()).grow(1)
                flex.addItem(shareButton)
            }

        return view
    }

    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.textAlignment = .center
        label.apply(
            text: R.string.phrase.fbIncreasePrivacyTitle().localizedUppercase,
            font: R.font.atlasGroteskRegular(size: Size.ds(18)),
            colorTheme: .white)
        return label
    }

    fileprivate func makeShareButton() -> Button {
        let button = Button()
        button.setImage(R.image.share(), for: .normal)
        return button
    }
}
