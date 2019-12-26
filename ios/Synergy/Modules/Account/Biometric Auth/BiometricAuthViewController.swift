//
//  BiometricAuthViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class BiometricAuthViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var policyType: LAType = {
        return BiometricAuth.currentDeviceEvaluatePolicyType()
    }()
    lazy var enableSwitchView = makeEnableSwitchView()
    lazy var enableSwitch = makeEnableSwitch()

    override func bindViewModel() {
        super.bindViewModel()

        enableSwitch.isOn = UserDefaults.standard.isAccountSecured

        enableSwitch.rx.isOn
            .skip(1)
            .subscribe(onNext: { [weak self] (isOn) in
                guard let self = self else { return }
                self.askAndToggleSecuredAccount(isSecured: isOn)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func askAndToggleSecuredAccount(isSecured: Bool) {
        let authorizeAccessCompletable = Completable.deferred { [weak self] in
            guard let self = self else { return Completable.never() }
            return isSecured ?
                BiometricAuth.authorizeAccess(reason: R.string.localizable.biometricRequireToSecure(self.policyType.text)) :
                BiometricAuth.authorizeAccess(reason: R.string.localizable.biometricRequireToRemoveSecure(self.policyType.text))
        }

        authorizeAccessCompletable
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                guard let account = Global.current.account else { return }
                do {
                    try KeychainStore.saveToKeychain(account.seed.core, isSecured: isSecured)
                } catch {
                    Global.log.error(error)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.enableSwitch.isOn = !isSecured
                guard let error = error as? AppError else { return }
                switch error {
                case .biometricNotConfigured:
                    self.showErrorAlert(message: R.string.error.biometricNotConfigured())
                case .biometricError:
                    self.showErrorAlert(message: R.string.error.biometricError())
                default:
                    return
                }
            })
            .disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()
        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.accountBiometricAuthDescription(policyType.text),
            font: R.font.atlasGroteskThin(size: Size.ds(22)),
            colorTheme: .tundora, lineHeight: 1.32)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                flex.addItem(descriptionLabel)
                flex.addItem(enableSwitchView).marginTop(40)
            }
    }
}

extension BiometricAuthViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountBiometricAuthTitle(policyType.text).localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeEnableSwitchView() -> UIView {
        let view = UIView()

        let titleSwitchLabel = Label()
        titleSwitchLabel.apply(
            text: R.string.phrase.accountBiometricAuthEnableButton(policyType.text),
            font: R.font.atlasGroteskThin(size: Size.ds(22)),
            colorTheme: .tundora, lineHeight: 1.32)

        view.flex.direction(.row)
            .define { (flex) in
                flex.addItem(enableSwitch)
                flex.addItem(titleSwitchLabel).marginLeft(40)
            }

        return view
    }

    fileprivate func makeEnableSwitch() -> Switch {
        return Switch()
    }
}
