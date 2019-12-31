//
//  ReactionTableViewCell.swift
//  Synergy
//
//  Created by Thuyen Truong on 12/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class ReactionTableViewCell: TableViewCell {

    // MARK: - Properties
    fileprivate lazy var timeLabel = makeTimeLabel()
    fileprivate lazy var descriptionLabel = makeDescriptionLabel()
    fileprivate lazy var reactionImageView = makeReactionImageView()

    // MARK: - Inits
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        themeService.rx
            .bind({ $0.reactionCellBackgroundColor }, to: rx.backgroundColor)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().padding(OurTheme.postCellPadding).define { (flex) in
                flex.addItem(timeLabel)
                flex.addItem(descriptionLabel).marginTop(12)
                flex.addItem(reactionImageView).marginTop(23).alignSelf(.start)
            }
            flex.addItem(SectionSeparator())
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Data
    func bindData(reaction: Reaction) {
        timeLabel.text = reaction.timestamp.toFormat(Constant.TimeFormat.reaction)
        descriptionLabel.setText(reaction.title)
        reactionImageView.image = reaction.reactionType?.reactionImage

        timeLabel.flex.markDirty()
        descriptionLabel.flex.markDirty()
        reactionImageView.flex.markDirty()
        flex.layout()
    }
}

extension ReactionTableViewCell {
    fileprivate func makeTimeLabel() -> Label {
        let label = Label()
        label.apply(text: "",
                    font: R.font.atlasGroteskRegular(size: Size.ds(14)),
                    colorTheme: .black)
        return label
    }

    fileprivate func makeDescriptionLabel() -> Label {
        let label = Label()
        label.apply(text: "",
                    font: R.font.atlasGroteskLight(size: Size.ds(16)),
                    colorTheme: .black, lineHeight: 1.2)
        return label
    }

    fileprivate func makeReactionImageView() -> ImageView {
        return ImageView()
    }
}
