//
//  AskNotificationsViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import UserNotifications
import OneSignal

class AskNotificationsViewController: ViewController {

    // MARK: - Properties
    lazy var notifyMeButton = makeNotifyMeButton()
    lazy var notNotifyMeButton = makeNotNotifyMeButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        notifyMeButton.rx.tap.bind { [weak self] in
            _ = self?.askForNotificationPermission()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] (notificationStatus) in
                    guard let self = self else { return }
                    switch notificationStatus {
                    case .authorized, .provisional:
                        UserDefaults.standard.enablePushNotification = true
                        self.gotoGetYourDataScreen()
                    default:
                        break
                    }
                    
                }, onError: { (error) in
                    Global.log.error(error)
                })
        }.disposed(by: disposeBag)
        
        notNotifyMeButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.enablePushNotification = false
            self.gotoGetYourDataScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let thumbImage = ImageView(image: R.image.hedgehogs())
        thumbImage.contentMode = .scaleAspectFill

        view.addSubview(thumbImage)
        thumbImage.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        super.setupViews()

        let dataRequestedTitle = Label()
        dataRequestedTitle.applyBlack(
            text: R.string.phrase.askNotificationsTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)))

        let dataRequestedDesc = Label()
        dataRequestedDesc.numberOfLines = 0
        dataRequestedDesc.applyBlack(
            text: R.string.phrase.askNotificationsDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem().height(45%)

                flex.addItem(dataRequestedTitle).marginTop(Size.dh(45))
                flex.addItem(dataRequestedDesc).marginTop(Size.dh(15))
                
                flex.addItem()
                    .position(.absolute).width(100%)
                    .left(OurTheme.paddingInset.left).bottom(Size.dh(30))
                    .define { (flex) in
                        flex.addItem(notifyMeButton)
                        flex.addItem(notNotifyMeButton).marginTop(Size.dh(15))
                }
            }
    }
}

// MARK: - Navigator
extension AskNotificationsViewController {
    func gotoGetYourDataScreen() {
        let viewModel = GetYourDataViewModel()
        navigator.show(segue: .getYourData(viewModel: viewModel), sender: self)
    }
}

extension AskNotificationsViewController {
    fileprivate func makeNotifyMeButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.notify_me())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }
    
    fileprivate func makeNotNotifyMeButton() -> Button {
        let button = Button(title: R.string.localizable.no_thanks())
        button.titleLabel?.font = R.font.atlasGroteskLight(size: Size.ds(18))
        themeService.rx
            .bind( { $0.themeColor }, to: button.rx.titleColor(for: .normal))
            .disposed(by: disposeBag)
        return button
    }
}
