//
//  EditingTextView.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class EditingTextView: UITextView {

    let disposeBag = DisposeBag()

    public convenience init() {
        self.init(frame: .zero)
        setupView()
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        font = Avenir.Heavy.size(24)

        themeService.rx
            .bind({ $0.textViewBackgroundColor }, to: rx.backgroundColor)
            .bind({ $0.textViewTextColor }, to: rx.textColor)
            .disposed(by: disposeBag)
    }
}
