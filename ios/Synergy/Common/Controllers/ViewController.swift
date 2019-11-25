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
    var mainView: UIView!
    var navigationViewHeightConstraint: Constraint!

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

    lazy var navigationView: UIView = {
        return UIView()
    }()

    // MARK: - Setup Views
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.layoutIfNeeded()
        contentView.flex.layout()
    }

    override func setupViews() {
        super.setupViews()

        let fullView = UIView()
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
                .inset(UIEdgeInsets(top: 0, left: Size.dw(18), bottom: Size.dw(34), right: Size.dw(18)))
        }
    }
}

extension ViewController {

    func setLightScreenTitle(text: String, color: UIColor? = nil) {
        screenTitleLabel.text = text
        screenTitleLabel.font = R.font.domaineSansTextRegular(size: Size.ds(36))

        if let color = color {
            screenTitleLabel.textColor = color
        } else {
            themeService.rx
                .bind({ $0.lightTextColor }, to: screenTitleLabel.rx.textColor)
                .disposed(by: disposeBag)
        }
    }
}

protocol BackNavigator {
    func showBlackBackItem()
    func showLightBackItem()
}

extension BackNavigator where Self: ViewController {

    func showBlackBackItem() {
        let backButton = Button()
        backButton.applyBlack(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14))
        )

        addIntoNavigationView(backButton: backButton)
    }

    func showLightBackItem() {
        let backButton = Button()
        backButton.applyLight(
            title: R.string.localizable.backNavigator().localizedUppercase,
            font: R.font.avenir(size: Size.ds(14))
        )

        addIntoNavigationView(backButton: backButton)
    }

    func tapToBack() {
        Navigator.default.pop()
    }

    fileprivate func addIntoNavigationView(backButton: Button) {
        navigationViewHeightConstraint.update(offset: Size.dh(50))
        navigationView.addSubview(backButton)

        backButton.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview()
        }

        backButton.rx.tap.bind { [weak self] in
            self?.tapToBack()
        }.disposed(by: disposeBag)
    }
}
