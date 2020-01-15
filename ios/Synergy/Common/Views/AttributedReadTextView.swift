//
//  AttributedReadTextView.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class AttributedReadTextView: UITextView {

    let disposeBag = DisposeBag()

    public convenience init(text: String) {
        self.init(frame: .zero)
        setupView()

        self.text = text
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
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        backgroundColor = .clear
        isEditable = false
    }
}
