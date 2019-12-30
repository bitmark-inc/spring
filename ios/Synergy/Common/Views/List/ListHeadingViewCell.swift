//
//  PostHeadingViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/9/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class ListHeadingViewCell: TableViewCell {

    // MARK: - Properties
    lazy var backButtonView = UIView()
    lazy var sectionTitleLabel = makeSectionTitleLabel()
    lazy var sectionTagLabel = makeSectionTagLabel()
    lazy var timelineLabel = makeTimelineLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem().padding(OurTheme.paddingInset)
                    .direction(.column).define { (flex) in
                        flex.addItem(backButtonView)

                        flex.addItem().direction(.row).marginTop(6).define { (flex) in
                            flex.addItem(sectionTitleLabel).shrink(1)
                            flex.addItem(sectionTagLabel).marginLeft(5).marginTop(-15)
                        }

                        flex.addItem(timelineLabel).marginTop(7)
                }

                flex.addItem(SectionSeparator()).marginTop(Size.dh(27))
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func fillInfo(
        backButton: Button,
        sectionInfo: (sectionTitle: String, taggedText: String?, timelineText: String?)) {

        backButtonView.flex.addItem(backButton)
        sectionTitleLabel.setText(sectionInfo.sectionTitle)
        sectionTagLabel.setText(sectionInfo.taggedText)
        timelineLabel.setText(sectionInfo.timelineText?.uppercased())
    }
}

extension ListHeadingViewCell {
    func makeSectionTitleLabel() -> Label {
        let label = Label()
        label.applyTitleTheme(text: "", colorTheme: .cognac)
        return label
    }

    func makeSectionTagLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.atlasGroteskLight(size: Size.ds(10)),
            lineHeight: 1.06)
        return label
    }

    func makeTimelineLabel() -> Label {
        let label = Label()
        label.applyBlack(
            text: "",
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            lineHeight: 1.06)
        return label
    }
}
