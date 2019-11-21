//
//  TextField.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class TextField: UITextField {

    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func setupViews() {
        backgroundColor = .clear
        font = Avenir.Heavy.size(36)
        adjustsFontSizeToFitWidth = true
        minimumFontSize = 20

        themeService.rx
            .bind({ $0.textFieldTextColor }, to: rx.textColor)
            .bind({ $0.textFieldPlaceholderColor }, to: rx.placeholderColor)
            .disposed(by: disposeBag)
    }
}
