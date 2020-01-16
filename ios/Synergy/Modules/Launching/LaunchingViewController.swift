//
//  LaunchingViewController.swift
//  Synergy
//
//  Created by Anh Nguyen on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxCocoa
import FlexLayout

class LaunchingViewController: ViewController, LaunchingNavigatorDelegate {

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if SettingsBundle.shouldShowReleaseNote() {
            gotoReleaseNoteScreen()
        } else {
            SettingsBundle.setVersion()
            navigate()
        }
    }

    override func setupViews() {
        setupBackground(backgroundView: ImageView(image: R.image.onboardingSplash()))
        super.setupViews()

        contentView.backgroundColor = .clear

        // *** Setup subviews ***
        let titleScreen = Label()
        titleScreen.apply(
            text: R.string.phrase.launchName().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(80)),
            colorTheme: .white)

        let descriptionLabel = Label()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.apply(
            text: R.string.phrase.launchDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(22)),
            colorTheme: .white, lineHeight: 1.125)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .alignItems(.center)
            .direction(.column).define { (flex) in
                flex.addItem(titleScreen).marginTop(Size.dh(123))
                flex.addItem(descriptionLabel)
            }
    }

    fileprivate func gotoReleaseNoteScreen() {
        navigator.show(segue: .releaseNote(buttonItemType: .continue), sender: self, transition: .replace(type: .none))
    }
}
