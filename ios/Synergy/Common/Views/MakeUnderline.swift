//
//  MakeUnderline.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class MakeUnderline: UIView {

    var originalView: UIView!
    var spacing: Int!

    let disposeBag = DisposeBag()

    init(originalView: UIView, spacing: Int = 12) {
        super.init(frame: CGRect.zero)
        self.originalView = originalView
        self.spacing = spacing

        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        let separateLine = SeparateLine(height: 5)

        addSubview(originalView)
        addSubview(separateLine)

        originalView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }

        separateLine.snp.makeConstraints { (make) in
            make.top.equalTo(originalView.snp.bottom).offset(spacing)
            make.leading.trailing.bottom.width.equalToSuperview()
        }
    }
}
