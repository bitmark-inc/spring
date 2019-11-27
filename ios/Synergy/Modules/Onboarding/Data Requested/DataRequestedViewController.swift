//
//  DataRequestedViewController.swift
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

class DataRequestedViewController: ViewController {

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
                    self.notifyMessageLabel.setText(R.string.phrase.dataRequestedNotifyMessage())

                    self.scheduleReminderNotification()

                case .denied:
                    self.notifyMeButton.isHidden = true
                    self.notifyMessageLabel.isHidden = false
                    self.notifyMessageLabel.setText(R.string.phrase.dataRequestedNotifyRejectedMessage())

                case .notDetermined:
                    self.notifyMeButton.isHidden = false
                    self.notifyMessageLabel.isHidden = true

                @unknown default:
                    fatalError()
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

    func scheduleReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = R.string.phrase.dataRequestedScheduleNotifyTitle()
        content.body = R.string.phrase.dataRequestedScheduleNotifyMessage()
        content.sound = UNNotificationSound.default
        content.badge = 1

        #if targetEnvironment(simulator)
        guard let date = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) else { return }
        #else
        guard let date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        #endif

        let triggerDate = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let identifier = Constant.NotificationIdentifier.checkFBArchive
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request)
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
            text: R.string.phrase.dataRequestedScreenTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)))

        let dataRequestedDesc = Label()
        dataRequestedDesc.numberOfLines = 0
        dataRequestedDesc.applyBlack(
            text: R.string.phrase.dataRequestedDescription(),
            font: R.font.atlasGroteskThin(size: Size.ds(18)),
            lineHeight: 1.2)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().height(50%)

            flex.addItem(dataRequestedTitle).marginTop(Size.dh(27))
            flex.addItem(dataRequestedDesc).marginTop(Size.dh(15))

            flex.addItem(notifyMeButton).position(.absolute).bottom(0).width(100%)
            flex.addItem(notifyMessageLabel).position(.absolute).bottom(0).width(100%)
        }
    }
}

extension DataRequestedViewController {
    fileprivate func makeNotifyMessageLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: R.string.phrase.dataRequestedNotifyRejectedMessage(),
            font: R.font.atlasGroteskBold(size: Size.ds(22)),
            lineHeight: 1.32, level: 1)
        label.isDescription = true
        return label
    }

    fileprivate func makeNotifyMeButton() -> SubmitButton {
        return SubmitButton(title: R.string.localizable.notify_me())
    }
}
