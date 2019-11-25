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

class ViewController: ThemedViewController {
    var viewModel: ViewModel?

    var screenTitleLabel: UILabel!
    var mainView: UIView!

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

        fullView.addSubview(screenTitleLabel)
        fullView.addSubview(contentView)

        screenTitleLabel.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
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
