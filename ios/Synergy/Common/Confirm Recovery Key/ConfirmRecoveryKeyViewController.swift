//
//  ConfirmRecoveryKeyViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ConfirmRecoveryKeyViewController: ViewController {

    // MARK: - Properties
    var recoveryKeyTextView: EditingTextView!
    var guideLabel: Label!
    var submitButton: SubmitButton!

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? ConfirmRecoveryKeyViewModel else { return }

        viewModel.submitEnabled
            .drive(submitButton.rx.isEnabled)
            .disposed(by: disposeBag)

        _ = recoveryKeyTextView.rx.textInput => viewModel.recoveryKeyStringRelay
    }

    override func setupViews() {
        super.setupViews()

        recoveryKeyTextView = EditingTextView()
        recoveryKeyTextView.autocapitalizationType = .none

        guideLabel = Label()
        submitButton = SubmitButton()

        contentView.addSubview(recoveryKeyTextView)
        contentView.addSubview(guideLabel)
        contentView.addSubview(submitButton)

        recoveryKeyTextView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }

        guideLabel.snp.makeConstraints { (make) in
            make.top.equalTo(recoveryKeyTextView.snp.bottom).offset(Size.dh(20))
            make.leading.trailing.equalToSuperview()
        }

        submitButton.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
