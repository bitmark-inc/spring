//
//  IncreasePrivacyListViewController.swift
//  Synergy
//
//  Created by Thuyen Truong on 1/14/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SwiftRichString

class IncreasePrivacyListViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var privacyListView = UIView()
    lazy var screenTitle = makeScreenTitle()

    var privacyOptionTitleTextViews = [IncreasePrivacyOption: AttributedReadTextView]()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = privacyListView.frame.size
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        var paddingScreenTitleInset = OurTheme.accountPaddingScreenTitleInset
        paddingScreenTitleInset.bottom = Size.dh(13)

        privacyListView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(paddingScreenTitleInset)
                flex.addItem(makeDescriptionLabel())

                for (index, privacyOption) in IncreasePrivacyOption.allCases.enumerated() {
                    flex.addItem(makePrivacyOptionView(increasePrivacyOption: privacyOption, index: index))
                        .marginTop(Size.ds(27))
                }
            }

        scroll.addSubview(privacyListView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(0).grow(1)
            }
    }
}

// MARK: - UITextViewDelegate
extension IncreasePrivacyListViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme != nil, let host = URL.host else {
            return false
        }

        guard let increasePrivacyOption = IncreasePrivacyOption(rawValue: host)
            else {
                return true
        }

        let viewModel = IncreasePrivacyViewModel(increasePrivacyOption: increasePrivacyOption)
        navigator.show(segue: .increasePrivacy(viewModel: viewModel), sender: self)

        if let privacyOptionTitleTextView = privacyOptionTitleTextViews[increasePrivacyOption] {
            increasePrivacyOption.click()
            privacyOptionTitleTextView.linkTextAttributes = [
                .foregroundColor: increasePrivacyOption.clickedStatusColor
            ]
            privacyOptionTitleTextView.attributedText = increasePrivacyOption.title
            privacyOptionTitleTextView.flex.markDirty()
            privacyListView.flex.markDirty()
            privacyListView.flex.layout(mode: .adjustHeight)
            scroll.contentSize = privacyListView.frame.size
        }

        return true
    }
}

// MARK: - Setup Views
extension IncreasePrivacyListViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.fbIncreasePrivacyTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.fbIncreasePrivacyDescription(6),
            font: R.font.atlasGroteskLight(size: Size.ds(12)),
            colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makePrivacyOptionView(increasePrivacyOption: IncreasePrivacyOption, index: Int) -> UIView {
        let indexLabel = Label()
        indexLabel.apply(
            text:  String(index + 1),
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            colorTheme: .black, lineHeight: 1.2)

        let titleTextView = AttributedReadTextView()
        titleTextView.delegate = self
        titleTextView.attributedText = increasePrivacyOption.title
        titleTextView.linkTextAttributes = [
            .foregroundColor: increasePrivacyOption.clickedStatusColor
        ]
        privacyOptionTitleTextViews[increasePrivacyOption] = titleTextView

        let actionGuideLabel = Label()
        actionGuideLabel.numberOfLines = 0
        actionGuideLabel.apply(
            font: R.font.atlasGroteskLight(size: Size.ds(16)),
            colorTheme: .black, lineHeight: 1.2)
        actionGuideLabel.attributedText = increasePrivacyOption.actionGuide

        let view = UIView()

        view.flex
            .direction(.row)
            .define { (flex) in
                flex.addItem(indexLabel).marginRight(Size.dw(14)).alignSelf(.start)
                flex.addItem().grow(1).alignItems(.stretch).define { (flex) in
                    flex.addItem(titleTextView)
                    flex.addItem(actionGuideLabel).marginTop(5)
                }
            }

        return view
    }
}

// MARK: - IncreasePrivacyOption
enum IncreasePrivacyOption: String, CaseIterable {
    case turnOffFaceRecognition
    case deleteAllEmailContacts
    case deleteAllPhoneContacts
    case optOutOfAdsFromPartner
    case optOutOfAdsFromActivity
    case optOutOfFriendsSeeingAds

    var title: NSAttributedString {
        let normal = Style {
            $0.font = self.hasClicked ? R.font.atlasGroteskRegularItalic(size: Size.ds(16)) : R.font.atlasGroteskLightItalic(size: Size.ds(16))
            $0.color = self.clickedStatusColor
        }

        let linkStyle = normal.byAdding {
            $0.linkURL = appURL
            $0.underline = (.single, self.clickedStatusColor)
        }

        return titleText.set(style: StyleXML(base: normal, ["a": linkStyle]))
    }

    var actionGuide: NSAttributedString {
        let normal = Style {
            $0.font = R.font.atlasGroteskLight(size: Size.ds(12))
            $0.color = themeService.attrs.blackTextColor
        }

        let bold = Style {
            $0.font = R.font.atlasGroteskRegular(size: Size.ds(12))
        }

        return actionGuideText.set(style: StyleXML(base: normal, ["b": bold]))
    }

    var clickedStatusColor: UIColor {
        return hasClicked ? ColorTheme.yukonGold.color : UIColor.black
    }

    var hasClicked: Bool {
        guard let clickedIncreasePrivacyURLs = UserDefaults.standard.clickedIncreasePrivacyURLs else {
            return false
        }

        return clickedIncreasePrivacyURLs.contains(rawValue)
    }

    func click() {
        var currentClickedURLs = UserDefaults.standard.clickedIncreasePrivacyURLs ?? []
        currentClickedURLs.append(rawValue)
        UserDefaults.standard.clickedIncreasePrivacyURLs = currentClickedURLs
    }

    var titleText: String {
        return NSLocalizedString("fb.increasePrivacy.\(rawValue).title", tableName: "Phrase", comment: "")
    }

    var actionGuideText: String {
        return NSLocalizedString("fb.increasePrivacy.\(rawValue).actionGuide", tableName: "Phrase", comment: "")
    }

    var appURL: URL {
        return URL(string: Constant.appName + "://\(rawValue)")!
    }

    var guideURL: URL {
        switch self {
        case .turnOffFaceRecognition:   return URL(string: "https://m.facebook.com/privacy/touch/facerec")!
        case .deleteAllEmailContacts:   return URL(string: "https://m.facebook.com/mobile/facebook/contacts")!
        case .deleteAllPhoneContacts:   return URL(string: "https://m.facebook.com/mobile/messenger/contacts")!
        case .optOutOfAdsFromPartner:   return URL(string: "https://m.facebook.com/control_center/checkup/third_party/?entry_product=account_settings_menu")!
        case .optOutOfAdsFromActivity:  return URL(string: "https://m.facebook.com/ads/settings/fpd")!
        case .optOutOfFriendsSeeingAds: return URL(string: "https://m.facebook.com/settings/ads/socialcontext")!
        }
    }
}
