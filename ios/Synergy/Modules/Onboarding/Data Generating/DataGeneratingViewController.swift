//
//  DataGeneratingViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import UserNotifications
import OneSignal

class DataGeneratingViewController: ViewController {

    // MARK: - Properties
    lazy var notifyMessageLabel = makeNotifyMessageLabel()
    lazy var notifyMeButton = makeNotifyMeButton()
    let notificationCenter = UNUserNotificationCenter.current()

    let notificationStatusRelay = BehaviorRelay<UNAuthorizationStatus>(value: .notDetermined)

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()

        notificationStatusRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notificationStatus) in
                guard let self = self else { return }
                switch notificationStatus {
                case .authorized, .provisional:
                    self.notifyMeButton.isHidden = true
                    self.notifyMessageLabel.isHidden = false
                    self.notifyMessageLabel.setText(R.string.phrase.dataGeneratingNotifyMessage())

                    guard let accountNumber = Global.current.account?.getAccountNumber() else { return }
                    OneSignal.promptForPushNotifications(userResponse: { _ in
                      OneSignal.sendTags([
                        Constant.OneSignalTag.key: accountNumber
                      ])
                    })

                case .denied:
                    self.notifyMeButton.isHidden = true
                    self.notifyMessageLabel.isHidden = false
                    self.notifyMessageLabel.setText(R.string.phrase.dataGeneratingNotifyRejectedMessage())

                case .notDetermined:
                    self.notifyMeButton.isHidden = false
                    self.notifyMessageLabel.isHidden = true

                @unknown default:
                    break
                }
            })
            .disposed(by: disposeBag)

        notificationCenter.getNotificationSettings { [weak self] (settings) in
            self?.notificationStatusRelay.accept(settings.authorizationStatus)
        }

        notifyMeButton.rx.tap.bind { [weak self] in
            _ = self?.askForNotificationPermission()
                .subscribe(onSuccess: { [weak self] in
                    self?.notificationStatusRelay.accept($0)
                }, onError: { (error) in
                    Global.log.error(error)
                })
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
            make.height.equalToSuperview().multipliedBy(0.47)
        }

        super.setupViews()

        let dataGeneratingTitle = Label()
        dataGeneratingTitle.adjustsFontSizeToFitWidth = true
        dataGeneratingTitle.applyBlack(
            text: R.string.phrase.dataGeneratingScreenTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)))

        let dataGeneratingDesc = Label()
        dataGeneratingDesc.numberOfLines = 0
        dataGeneratingDesc.applyBlack(
            text: R.string.phrase.dataGeneratingDescription(),
            font: R.font.atlasGroteskThin(size: Size.ds(18)),
            lineHeight: 1.2)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().height(47%)

            flex.addItem(dataGeneratingTitle).marginTop(Size.dh(27))
            flex.addItem(dataGeneratingDesc).marginTop(Size.dh(15))

            flex.addItem(notifyMeButton).position(.absolute).bottom(0).width(100%)
            flex.addItem(notifyMessageLabel).position(.absolute).bottom(0).width(100%)
        }
    }
}

extension DataGeneratingViewController {

    fileprivate func makeNotifyMessageLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: R.string.phrase.dataGeneratingNotifyRejectedMessage(),
            font: R.font.atlasGroteskBold(size: Size.ds(22)),
            lineHeight: 1.32, level: 1)
        label.isDescription = true
        return label
    }

    fileprivate func makeNotifyMeButton() -> SubmitButton {
        return SubmitButton(title: R.string.localizable.notify_me())
    }
}
