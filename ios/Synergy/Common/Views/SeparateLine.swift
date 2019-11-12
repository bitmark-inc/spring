//
//  SeparateLine.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class SeparateLine: UIView {

  let disposeBag = DisposeBag()

  init(height: Int) {
    super.init(frame: CGRect.zero)

    snp.makeConstraints { (make) in
      make.height.equalTo(height)
    }

    setupViews()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupViews()
  }

  func setupViews() {
    themeService.rx
      .bind({ $0.separateLineColor }, to: rx.backgroundColor)
      .disposed(by: disposeBag)
  }
}
