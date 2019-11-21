//
//  IconButtonView.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class IconButtonView: UIView {

    var icon: String!
    var button: UIButton!

    let disposeBag = DisposeBag()

    init(icon: String, _ button: UIButton) {
        super.init(frame: CGRect.zero)
        self.button = button
        self.icon = icon

        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        let iconImageView = ImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(named: icon)!

        button.titleLabel?.font = Avenir.Heavy.size(32)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.textAlignment = .center

        addSubview(iconImageView)
        addSubview(button)

        iconImageView.snp.makeConstraints { (make) in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(Size.dw(23))
            make.height.equalTo(Size.dh(32))
        }

        button.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.top.trailing.bottom.equalToSuperview()
        }
    }
}
