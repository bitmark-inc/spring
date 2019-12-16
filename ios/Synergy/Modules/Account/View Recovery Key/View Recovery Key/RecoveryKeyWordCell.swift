//
//  RecoveryKeyWordCell.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/16/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class RecoveryKeyWordCell: CollectionViewCell {

    // MARK: - Properties
    lazy var wordLabel = makeWordLabel()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Handlers
    func setData(word: String) {
        wordLabel.text = word
    }

    // MARK: - Setup Views
    func setupViews() {
        contentView.flex.addItem(wordLabel).width(100%).height(100%)
    }
}

extension RecoveryKeyWordCell {
    fileprivate func makeWordLabel() -> Label {
        let label = Label()
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.apply(text: "", font: R.font.atlasGroteskLight(size: Size.ds(48)), colorTheme: .tundora, lineHeight: 1.32)
        return label
    }
}
