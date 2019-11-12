//
//  UnderlinedTextField.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

class UnderlinedTextField: TextField {

  init() {
    super.init(frame: CGRect.zero)

    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup Views
  override func setupViews() {
    super.setupViews()

    font = Avenir.Heavy.size(20)

    let separateView = UIView()

    themeService.rx
      .bind({ $0.separateLineColor }, to: separateView.rx.backgroundColor)
      .disposed(by: disposeBag)

    addSubview(separateView)

    separateView.snp.makeConstraints { (make) in
      make.height.equalTo(3)
      make.leading.trailing.equalToSuperview()
      make.top.equalTo(snp.bottom).offset(3)
    }
  }
}
