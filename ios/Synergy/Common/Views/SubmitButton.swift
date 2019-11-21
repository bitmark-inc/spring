//
//  SubmitButton.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift

class SubmitButton: UIButton {

    let disposeBag = DisposeBag()

    required init(title: String = "") {
        super.init(frame: .zero)

        setTitle(title, for: .normal)

        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel?.font = R.font.atlasGroteskRegular(size: Size.ds(18))

        themeService.rx
            .bind({ UIImage(color: $0.buttonBackground, size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .normal))
            .bind({ UIImage(color: $0.buttonBackground.withAlphaComponent(0.5), size: CGSize(width: 1, height: 1)) }, to: rx.backgroundImage(for: .disabled))
            .bind({ $0.buttonTextColor }, to: rx.titleColor(for: .normal))
            .bind({ $0.buttonTextColor.withAlphaComponent(0.5) }, to: rx.titleColor(for: .disabled))
            .disposed(by: disposeBag)

        themeService.rx
            .disposed(by: disposeBag)

        snp.makeConstraints { (make) in
            make.height.equalTo(Size.dh(55))
        }
    }
}
