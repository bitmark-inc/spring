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

class ViewController: ThemedViewController, Navigatable {

    var viewModel: ViewModel?
    var navigator: Navigator! = Navigator.default
    var buttonItemType: ButtonItemType?

    lazy var contentView: UIView = makeContentView()

    init(viewModel: ViewModel? = nil) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }

    let isLoading = BehaviorRelay(value: false)

    // MARK: - Setup Views
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.layoutIfNeeded()
        contentView.flex.layout()
    }

    override func setupViews() {
        super.setupViews()

        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
    }
}

extension ViewController {
    fileprivate func makeContentView() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        return view
    }

    func themeForContentView() {
        themeService.rx
            .bind({ $0.background }, to: contentView.rx.backgroundColor)
            .disposed(by: disposeBag)
    }
}
