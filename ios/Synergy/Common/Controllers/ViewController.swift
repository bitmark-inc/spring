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
                .inset(UIEdgeInsets(top: 0, left: Size.dw(18), bottom: Size.dw(34), right: Size.dw(18)))
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
