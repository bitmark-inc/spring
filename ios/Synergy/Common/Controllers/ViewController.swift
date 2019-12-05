//
//  ViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SnapKit

class ViewController: ThemedViewController {
    var viewModel: ViewModel?

    var screenTitleLabel: UILabel!
    let navigationViewHeight = Size.dh(50)
    var navigationViewHeightConstraint: Constraint!

    init(viewModel: ViewModel?) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }

    let isLoading = BehaviorRelay(value: false)

    lazy var fullView = UIView()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        return view
    }()

    lazy var navigationView = UIView()

    // MARK: - Setup Views
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fullView.layoutIfNeeded()
        contentView.flex.layout()
    }

    override func setupViews() {
        super.setupViews()

        screenTitleLabel = UILabel()
        screenTitleLabel.font = UIFont.navigationTitleFont

        fullView.addSubview(navigationView)
        fullView.addSubview(screenTitleLabel)
        fullView.addSubview(contentView)

        navigationView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            navigationViewHeightConstraint = make.height.equalTo(0).constraint
        }

        screenTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(navigationView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(screenTitleLabel.snp.bottom).offset(Size.dh(45))
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(fullView)
        fullView.snp.makeConstraints { (make) in
            make.edges.equalTo(view.safeAreaLayoutGuide)
                .inset(UIEdgeInsets(top: 0, left: Size.dw(18), bottom: Size.dh(34), right: Size.dw(18)))
        }
    }
}

extension ViewController {

    func setThemedScreenTitle(text: String) {
        screenTitleLabel.text = text
        screenTitleLabel.font = R.font.domaineSansTextRegular(size: Size.ds(36))

        themeService.rx
            .bind({ $0.themeColor }, to: screenTitleLabel.rx.textColor)
            .disposed(by: disposeBag)
    }

    func setLightScreenTitle(text: String) {
        screenTitleLabel.text = text
        screenTitleLabel.font = R.font.domaineSansTextRegular(size: Size.ds(36))

        themeService.rx
            .bind({ $0.lightTextColor }, to: screenTitleLabel.rx.textColor)
            .disposed(by: disposeBag)
    }
}

class TabPageViewController: ThemedViewController {
    var viewModel: ViewModel?

    var screenTitleLabel: UILabel!
    var titleView: UIView!
    let navigationViewHeight = Size.dh(50)

    init(viewModel: ViewModel?) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }

    let isLoading = BehaviorRelay(value: false)

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        return view
    }()

    lazy var backNavigationButton: Button = {
        let btn = Button()
        btn.applyBlack(title: R.string.localizable.backNavigator(),
                       font: R.font.avenir(size: 14))
        btn.isHidden = true
        return btn
    }()

    // MARK: - Setup Views
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        contentView.flex.layout()
    }

    override func setupViews() {
        super.setupViews()

        let fullView = UIView()
        screenTitleLabel = UILabel()
        screenTitleLabel.font = UIFont.navigationTitleFont
        
        titleView = UIView()
        
        fullView.addSubview(backNavigationButton)
        fullView.addSubview(contentView)
        
        backNavigationButton.isUserInteractionEnabled = true
        
        titleView.flex.direction(.row).define { (flex) in
            flex.addItem(screenTitleLabel).marginLeft(17)
        }
        contentView.flex.direction(.column).addItem(titleView).height(42).width(100%)

        var backButtonHeight: CGFloat = 0
        if let v = self.navigationController?.viewControllers,
            v.count > 1 {
            backNavigationButton.isHidden = false
            backButtonHeight = 24
        }

        backNavigationButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(17)
            make.height.equalTo(backButtonHeight)
        }

        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(backNavigationButton).offset(backButtonHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(fullView)
        fullView.snp.makeConstraints { (make) in
            make.edges
                .equalTo(view.safeAreaLayoutGuide)
                .inset(UIEdgeInsets(top: 17, left: 0, bottom: 0, right: 0))
        }
    }
    
    override func bindViewModel() {
        super.bindViewModel()
        
        backNavigationButton.rx.tap.bind { [unowned self] in
            self.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
    }
}

extension TabPageViewController {

    func setThemedScreenTitle(text: String, color: UIColor?) {
        screenTitleLabel.text = text
        screenTitleLabel.font = R.font.domaineSansTextLight(size: Size.ds(36))
        screenTitleLabel.textColor = color

//        themeService.rx
//            .bind({ $0.themeColor }, to: screenTitleLabel.rx.textColor)
//            .disposed(by: disposeBag)
    }

    func setLightScreenTitle(text: String) {
        screenTitleLabel.text = text
        screenTitleLabel.font = R.font.domaineSansTextLight(size: Size.ds(36))

        themeService.rx
            .bind({ $0.lightTextColor }, to: screenTitleLabel.rx.textColor)
            .disposed(by: disposeBag)
    }
}
