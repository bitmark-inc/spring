//
//  TableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit

class TableViewCell: UITableViewCell {

  var contentCell: UIView!
  let disposeBag = DisposeBag()

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupViews()
  }

  // MARK: - Setup views
  func setupViews() {
    backgroundColor = .clear
    selectionStyle = .none

    contentCell = UIView()

    let separateLine = UIView()
    themeService.rx
      .bind({ $0.separateLineColor }, to: separateLine.rx.backgroundColor)
      .disposed(by: disposeBag)

    addSubview(contentCell)
    addSubview(separateLine)

    contentCell.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
        .inset(UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 18))
    }

    separateLine.snp.makeConstraints { (make) in
      make.top.equalTo(contentCell.snp.bottom).offset(4)
      make.leading.bottom.equalToSuperview()
      make.trailing.equalToSuperview().offset(-18)
      make.height.equalTo(1)
    }
  }
}
