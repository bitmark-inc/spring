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
    lazy var dataRequestedTitleLabel = makeDataRequestedTitleLabel()
    lazy var dataRequestedDescLabel = makeDataRequestedDescLabel()
    lazy var dataRequestedTimeDescLabel = makeDataRequestedTimeDescLabel()
    lazy var checkNowButton = makeCheckNowButton()
    let notificationCenter = UNUserNotificationCenter.current()

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
        
        guard let viewModel = viewModel as? DataRequestedViewModel else { return }
        
        scheduleReminderNotificationIfEnable()
        
        guard let archiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt else {
            Global.log.error(AppError.emptyLocal)
            return
        }

        dataRequestedTimeDescLabel.setText(
            R.string.phrase.dataRequestedDescriptionTime(
                archiveCreatedAt.string(withFormat: Constant.TimeFormat.archive)))
        
        switch viewModel.mission {
        case .requestData:
            dataRequestedTitleLabel.setText(R.string.phrase.dataRequestedScreenTitle().localizedUppercase)
            dataRequestedDescLabel.setText(R.string.phrase.dataRequestedDescription())

        case .checkRequestedData:
            dataRequestedTitleLabel.setText(R.string.phrase.dataRequestedScreenTitle().localizedUppercase)
            dataRequestedDescLabel.setText(R.string.phrase.dataRequestedCheckDescription())

        case .downloadData:
            dataRequestedTitleLabel.setText(R.string.phrase.dataRequestedWaitingScreenTitle().localizedUppercase)
            dataRequestedDescLabel.setText(R.string.phrase.dataRequestedWaitingDescription())

        case .none:
            break
        }
        
        checkNowButton.isHidden = viewModel.mission != .checkRequestedData
        checkNowButton.rx.tap.bind { [weak self] in
            self?.gotoDownloadFBArchiveScreen()
        }.disposed(by: disposeBag)
    }

    func scheduleReminderNotificationIfEnable() {
        guard UserDefaults.standard.enablePushNotification else { return }

        let content = UNMutableNotificationContent()
        content.body = R.string.phrase.dataRequestedScheduleNotifyMessage()
        content.sound = UNNotificationSound.default
        content.badge = 1

        #if targetEnvironment(simulator)
        guard let date = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) else { return }
        let triggerDate = Calendar.current.dateComponents([.second], from: date)
        #else
        guard let date = Calendar.current.date(byAdding: .minute, value: -1, to: Date()) else { return }
        let triggerDate = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        #endif

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

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem().height(45%)

                flex.addItem(dataRequestedTitleLabel).marginTop(Size.dh(45))
                flex.addItem(dataRequestedDescLabel).marginTop(Size.dh(15))
                flex.addItem(dataRequestedTimeDescLabel).marginTop(Size.dh(10))
                
                flex.addItem(checkNowButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension DataRequestedViewController {
    func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(.downloadData)
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self)
    }
}

extension DataRequestedViewController {
    fileprivate func makeDataRequestedTitleLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.domaineSansTextLight(size: Size.ds(36)))
        return label
    }
    
    fileprivate func makeDataRequestedDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.applyBlack(
            text: "",
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)
        return label
    }
    
    fileprivate func makeCheckNowButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.check_now())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeDataRequestedTimeDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: "",
            font: R.font.atlasGroteskThinItalic(size: Size.ds(18)),
            colorTheme: .black, lineHeight: 1.2)
        return label
    }
}
