//
//  Button.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class Button: UIButton {

    let disposeBag = DisposeBag()

    required init(title: String = "") {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        themeService.rx
            .bind({ $0.buttonTextColor }, to: rx.titleColor(for: .normal))
            .disposed(by: disposeBag)
    }
}
