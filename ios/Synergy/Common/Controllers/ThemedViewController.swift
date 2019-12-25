//
//  ThemedViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxTheme
import SVProgressHUD

class ThemedViewController: UIViewController {

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        themeService.switchThemeType(for: traitCollection.userInterfaceStyle)

        setupViews()
        loadData()
        bindViewModel()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        themeService.switchThemeType(for: traitCollection.userInterfaceStyle)
    }

    func loadData() {}

    func setupViews() {
        themeService.rx
            .bind({ $0.background }, to: view.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    func setupBackground(backgroundView: UIView) {
        if ((backgroundView as? ImageView) != nil) {
            backgroundView.contentMode = .scaleToFill
        }

        // *** Setup UI in view ***
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func bindViewModel() {
        loadingState
            .bind(to: SVProgressHUD.rx.state)
            .disposed(by: disposeBag)
    }
}
