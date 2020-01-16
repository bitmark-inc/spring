//
//  ReleaseNoteViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/8/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Intercom

class ReleaseNoteViewController: ViewController, BackNavigator, LaunchingNavigatorDelegate {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var versionLabel = makeVersionLabel()
    lazy var versionDateLabel = makeVersionDateLabel()
    lazy var feedbackTextView = makeFeedbackTextView()
    lazy var continueButton = makeContinueButton()

    lazy var releaseNotesURL: URL? = {
        let releaseNotesFile = "ReleaseNotes"
        return Bundle.main.url(forResource: releaseNotesFile, withExtension: "md")
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        if let pathToInfoPlist = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let updateDate = try? FileManager.default.attributesOfItem(atPath: pathToInfoPlist)[.modificationDate] as? Date {
            let durationInDays = Calendar.current.dateComponents([.day], from: updateDate)
            versionDateLabel.setText(R.string.phrase.releaseNoteAppVersionDate(durationInDays.day!))
        }

        continueButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            loadingState.onNext(.loading)
            SettingsBundle.setVersion()
            self.navigate()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        var marginBottomForContent: CGFloat = 60

        if buttonItemType == .continue {
            marginBottomForContent += 50.0
        }

        contentView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem()
                    .grow(1).marginBottom(marginBottomForContent)
                    .define { (flex) in
                        flex.addItem(screenTitle).margin(OurTheme.titlePaddingWithoutBack)

                        flex.addItem()
                            .direction(.row).justifyContent(.spaceBetween)
                            .define { (flex) in
                                flex.addItem(versionLabel)
                                flex.addItem(versionDateLabel)
                            }

                        flex.addItem(feedbackTextView).marginTop(10).height(0).grow(1)
                    }

                switch buttonItemType {
                case .back:
                    let blackBackItem = makeBlackBackItem()
                    contentView.flex.addItem(blackBackItem)
                        .position(.absolute).top(0).left(OurTheme.paddingInset.left)

                case .continue:
                    flex.addItem(continueButton)
                        .width(100%)
                        .position(.absolute)
                        .left(OurTheme.paddingInset.left)
                        .bottom(OurTheme.paddingBottom)
                default:
                    break
                }
            }
    }
}

// MARK: - UITextViewDelegate
extension ReleaseNoteViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        guard URL.scheme != nil, let host = URL.host else {
            return false
        }

        switch host {
        case AppLink.support.rawValue:
            Intercom.presentMessenger()
        default:
            return false
        }

        return true
    }
}

extension ReleaseNoteViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.releaseNoteTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)),
            colorTheme: .black, lineHeight: 1.056)
        return label
    }

    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continueArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeVersionLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.releaseNoteAppVersion(UserDefaults.standard.appVersion ?? "--"),
            font: R.font.atlasGroteskRegular(size: 22),
            colorTheme: .black)
        return label
    }

    fileprivate func makeVersionDateLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.atlasGroteskLight(size: 18), colorTheme: .tundora)
        return label
    }

    fileprivate func makeFeedbackTextView() -> UITextView {
        var content = ""
        if let releaseNotesURL = releaseNotesURL {
            do {
                content = try String(contentsOf: releaseNotesURL, encoding: .utf8)
            } catch {
                Global.log.error(error)
            }
        }

        let textView = AttributedReadTextView()
        textView.delegate = self
        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.releaseNoteContent(content, Constant.supportEmail),
            lineHeight: 1.315,
            attributes: [.font: R.font.atlasGroteskLight(size: 22)!, .foregroundColor: ColorTheme.tundora.color],
            links: [(text: Constant.supportEmail, url: AppLink.support.path)],
            linkAttributes: [
                .foregroundColor: ColorTheme.cornFlowerBlue.color
            ])
        return textView
    }
}
